require 'timed_set'
require 'csv'

OPEN_ASSETS_NAME_SHORT_CHAR_LIMIT = 10

class ProductsController < ProductController
  respond_to :html, :json

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :follow, :unfollow, :announcements, :welcome]
  before_action :set_product,
    only: [:show, :activity, :old, :edit, :update, :follow, :announcements, :unfollow, :metrics, :flag, :feature, :launch]

  after_action :record_page_view, only: [:show]

  MARK_DISPLAY_LIMIT = 14
  PRODUCT_MARK_DISPLAY_LIMIT = 6

  def new
    @product = Product.new
    @product.user = current_user

    @four_word_story_example = [
        'Support comes from people, not software.',
        'Find, share, and discuss indie games.'
      ].sample

    @idea = Idea.find_by(id: params[:idea_id])

    if @idea
      @participants = @idea.participants.map{|a| UserSerializer.new(a)}
    else
      @participants = []
    end

    render layout: 'application'
  end

  def checklistitems
    find_product!
    ordered_tasks = @product.tasks.where.not(display_order: nil).order(display_order: :asc)
    completed_ordered_tasks = ordered_tasks.where.not(state: ["open", "allocated"]).count

    if ordered_tasks.count == 0
      completion = 0
    else
      completion = ((completed_ordered_tasks.to_f / ordered_tasks.count.to_f)*100).round(2)
    end

    ordered_tasks = ActiveModel::ArraySerializer.new(ordered_tasks.take(6))

    render json: {tasks: ordered_tasks, percent_completion: completion}
  end

  def greenlight
    find_product!
    authorize! :update, @product

    @product.update!({state: "greenlit", greenlit_at: Time.now})
    render json: {message: "Success"}
  end

  def ownership
    find_product!
    eom = 1.month.ago
    if params[:eom]
      eom = Date.parse(params[:eom])
    end
    at = TransactionLogEntry.end_of_month(eom)
    ownership = CsvCompiler.new.get_product_partner_breakdown(@product, at)

    csv_file = CSV.generate({}) do |csv|
      ownership.each do |a|
        csv << a
      end
    end
    send_data csv_file, :type => 'text/csv', :filename => "#{@product.slug}-#{at.iso8601}.csv"
  end

  def create
    if idea_id = params[:product].delete(:idea_id)
      @idea = Idea.find(idea_id)
      return redirect_to action: :new, layout: 'application' unless @idea.user == current_user
    end

    if @idea
      @product = create_product_with_params(@idea)
    else
      @product = create_product_with_params
    end

    if @product.valid?
      respond_with(@product, location: product_path(@product))
    else
      render action: :new, layout: 'application'
    end
  end

  def coin
    find_product!

    if @product.coin_info.nil?
      render json: {}
      return
    end

    render json: {
      asset_ids: [@product.coin_info.asset_address],
      name_short: @product.name[0, OPEN_ASSETS_NAME_SHORT_CHAR_LIMIT],
      name: @product.name,
      contract_url: ProductSerializer.new(@product).full_url,
      issuer: 'Assembly.com',
      description: @product.pitch,
      description_mime: "text/x-markdown; charset=UTF-8",
      type: "Ownership",
      divisibility: 0,
      link_to_website: true,
      icon_url: @product.full_logo_url,
      image_url: @product.full_logo_url
    }
  end

  def set_up_chat
    return unless ENV["LANDLINE_URL"]
    if room = ChatRoom.find_by(product: @product)
      room.migrate_to(ChatMigrator.new, '/teams/assembly/rooms')
    end
  end

  def welcome
    find_product!
    authorize! :update, @product
  end

  def admin
    return redirect_to(product_url(@product)) unless current_user && current_user.is_staff?
    find_product!
  end

  def stories
    find_product!
    stories = Story.joins(:activities).
      where(activities: { product_id: @product}).
      order(created_at: :desc).uniq.page(params[:page]).per(20)

    render json: stories,
      serializer: PaginationSerializer,
      each_serializer: TimelineStorySerializer,
      root: :stories
  end

  def activity
    respond_to do |format|
      format.html { render 'show' }
      format.json { render json: {}, status: :ok }
    end
  end

  def trust
    set_product
    respond_to do |format|
      format.html { render }
      format.json { render json: @product }
    end
  end

  def flag
    return redirect_to(product_url(@product)) unless current_user && current_user.is_staff?
    if request.post?
      @product.touch(:flagged_at)
      @product.update_attribute(:flagged_reason, params[:message])
      # TODO: disabling email to idea submitter for time being
      # ProductMailer.delay(queue: 'mailer').flagged(current_user.id, @product.id, params[:message])
      return redirect_to product_url(@product)
    end
  end

  def feature
    return head(:forbidden) unless current_user && current_user.is_staff?
    @product.touch(:featured_on)
    return redirect_to product_url(@product)
  end

  def show
    show_product
  end

  def plan
    set_product
  end

  def edit
    authorize! :update, @product
    @upgrade_stylesheet = true
  end

  def update
    authorize! :update, @product

    # since we don't know what the subsections hash
    # will look like, we need to have this janky if-check
    if params[:subsections]
      if params[:subsections].blank?
        @product.update(subsections: {})
      else
        @product.update(subsections: params[:subsections])
      end
    else
      @product.update!(product_params)
    end

    respond_with(@product)
  end

  def follow
    @product.watch!(current_user)

    Activities::Follow.publish!(
      actor: current_user,
      subject: @product,
      target: @product
    )

    render nothing: true, :status => :ok
  end

  def announcements
    authenticate_user!
    set_product
    @product.announcements!(current_user)
    respond_with @product, location: product_wips_path(@product)
  end

  def unfollow
    @product.unwatch!(current_user)
    render nothing: true, :status => :ok
  end

  def launch
    authorize! :update, @product
    ApplyForPitchWeek.perform_async(@product.id, current_user.id)
    flash[:applied_for_pitch_week] = true
    respond_with @product, location: product_path(@product)
  end

  def import
    render layout: 'application'
  end

  def start
    render layout: 'application'
  end


  # private

  def setup_core_team(product)
    core_team_ids = Array(params[:core_team])
    core_team_members = User.where(id: core_team_ids.select(&:uuid?))
    core_team_members.each do |user|
      product.core_team_memberships.create(user: user)
    end
  end

  def spread_the_word(idea, product, chosen_ids)
    chosen_ids.each do |chosen_id|
      EmailLog.send_once(chosen_id, idea.slug) do
        PartnershipMailer.delay(queue: 'mailer').create(chosen_id, product.id, idea.id)
      end
    end
    Tweeter.tweet_new_product(idea, product)
  end

  def create_product_with_params(idea=nil)
    product = current_user.products.create(product_params)
    if product.valid?
      product.team_memberships.create!(user: current_user, is_core: true)

      product.watch!(current_user)
      ChatRoom.create_for_product(product, current_user)

      ownership = params[:ownership] || {}

      setup_core_team(product)

      product.update_partners_count_cache
      product.save!

      flash[:new_product_callout] = true

      Karma::Kalkulate.new.award_for_product_to_stealth(product)
      product.retrieve_key_pair
      if idea
        idea.update(product_id: product.id)
        the_elect = (params[:product][:partner_ids] || "").split(",").flatten
        GiveCoinsToParticipants.new.perform(the_elect, product.id)

        product.reload
        spread_the_word(idea, product, the_elect)
      end

      AutoBounty.new.product_initial_bounties(product)
      current_user.touch
      product.reload
      # Set up a room on Landline
      set_up_chat
    end
    product
  end

  def show_product
    respond_to do |format|
      format.html { render 'show' }
      format.json {
        render json: {
          product: ProductSerializer.new(
            @product,
            scope: current_user
          ).as_json.merge(partners: json_array(@product.partners(20))),
          screenshots: ActiveModel::ArraySerializer.new(
            @product.screenshots.order(position: :asc).limit(6),
            each_serializer: ScreenshotSerializer
          )
        }
      }
    end
  end

  def make_idea
    authorize! :update, @product
    product = Product.find_by_slug!(params[:product_id])

    @idea = Idea.create_with_discussion(
      product.user,
      name: product.pitch,
      body: product.description,
      created_at: product.created_at,
      flagged_at: product.flagged_at,
      founder_preference: true,
      product_id: product.id
    )

    (product.votes + product.watchings + product.team_memberships).map do |h|
      next unless h.user_id

      heart = @idea.news_feed_item.hearts.find_or_initialize_by(user_id: h.user_id)
      heart.created_at = h.created_at
      heart.save!
    end

    @idea.news_feed_item.update_column('last_commented_at', product.created_at)

    render json: @idea
  end

  def filter_params
    params.permit(:archived, :mark, :type)
  end

  def product_params
    fields = [
      :name,
      :pitch,
      :lead,
      :description,
      :tags_string,
      :greenlit_at,
      :poster,
      :state,
      :homepage_url,
      :try_url,
      :you_tube_video_url,
      :terms_of_service,
      {:tags => []},
      :partner_ids,
      :idea_id
    ] + Product::INFO_FIELDS.map(&:to_sym)

    params.require(:product).permit(*fields)
  end

  def record_page_view
    page_views = TimedSet.new($redis, "#{@product.id}:show")
    if page_views.add(request.remote_ip)
      Product.increment_counter(:view_count, @product.id)
      page_views.drop_older_than(5.minutes)
    end
  end
end

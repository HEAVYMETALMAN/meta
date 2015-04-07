class AvatarSerializer < ApplicationSerializer
  attributes :username, :avatar_url
  attributes :url, :coinprism_url, :wallet_public_address

  def avatar_url
    object.avatar.url(288).to_s
  end

  def coinprism_url
    object.coinprism_url
  end

  def wallet_public_address
    object.wallet_public_address
  end

  def url
    user_path(object)
  end

end

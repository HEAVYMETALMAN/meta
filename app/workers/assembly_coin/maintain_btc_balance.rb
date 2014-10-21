module AssemblyCoin
  class MaintainBtcBalance < AssemblyCoin::Worker

    def perform(product_id)
      product = Product.find_by(id: product_id)

      if product.state == 'greenlit' or product.state == 'profitable'
        destination = product.wallet_public_address

        current_btc=OpenAssets::Transactions.new.get_btc_balance(destination)
        current_time =  Time.now

        last_checked_time = product.last_checked_btc
        if last_checked_time.nil?
          last_checked_time = 0
        end

        time_since_last_checked = current_time.to_i - last_checked_time.to_i

        if ENV['MIN_PRODUCT_BTC'].to_f > current_btc and time_since_last_checked > 3600 then
          amount = ENV['MIN_PRODUCT_BTC'].to_f - current_btc + ENV['STANDARD_BTC_FEE'].to_f*4

          product.update!(last_checked_btc: current_time)

          public_address = ENV['CENTRAL_ADDRESS_PUBLIC_ADDRESS']

          Rails.logger.info "[coins] Sending #{amount} BTC to #{destination} from #{public_address}"
          OpenAssets::Transactions.new.send_btc(destination, amount)
        else
          Rails.logger.info "[coins] #{product.id} wallet has sufficient Bitcoin"
        end
      end
    end
  end
end
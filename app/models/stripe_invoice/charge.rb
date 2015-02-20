module StripeInvoice
  class Charge < ActiveRecord::Base
    attr_accessible :id, :invoice_number, :stripe_id, :json, 
      :owner_id, :date, :amount, :discount, :total, :subtotal, :period_start, 
      :period_end, :currency 
    
    alias_attribute :number, :invoice_number

    serialize :json, JSON
    
    def indifferent_json
     @json ||= json.with_indifferent_access 
    end
    
    def datetime
      Time.at(date).to_datetime
    end
    
    def owner
      @owner ||= Koudoku.owner_class.find(owner_id)
    end
    
    def refunds
      indifferent_json[:refunds]
    end

    def total_refund
      refunds.inject(0){ |total,refund| total + refund[:amount]}
    end
    
    # builds the invoice from the stripe CHARGE object
    # OR updates the existing invoice if an invoice for that id exists
    def self.create_from_stripe(stripe_charge)
      charge = Charge.find_by_stripe_id(stripe_charge[:id])
      
      raise "won't build for unpaid charges" unless stripe_charge.paid
      # for existing invoices just update and be done
      if charge.present?
        charge.update_attribute(:json, stripe_charge)
        return charge 
      end
      
      owner = get_subscription_owner stripe_charge
      
      return unless owner
      
      stripe_invoice = Stripe::Invoice.retrieve stripe_charge[:invoice]
      last_charge = Charge.last
      new_charge_number = (last_charge ? (last_charge.id * 7) : 1).to_s.rjust(5, '0')
      
      charge_date = Time.at(stripe_charge[:created]).utc.to_datetime
      
      charge = Charge.create({
        stripe_id: stripe_charge[:id], 
        owner_id: owner.id,
        date: stripe_charge[:created],
        amount: stripe_charge[:amount],
        subtotal: stripe_invoice[:subtotal],
        discount: stripe_invoice[:discount],
        total: stripe_invoice[:total],
        currency: stripe_invoice[:currency],
        period_start: stripe_invoice[:period_start],
        period_end: stripe_invoice[:period_end],
        invoice_number: "#{charge_date.year}-#{new_charge_number}",
        json: stripe_charge
      })
      
      puts "Charge saved: #{charge.id}"
    end
    
    private 
    def self.get_subscription_owner(stripe_charge)
      # ::Subscription is generated by Koudoku, but lives in main_app
      subscription = ::Subscription.find_by_stripe_id(stripe_charge.customer)
      return nil if subscription.nil?
      owner = subscription.subscription_owner 
    end
  end
end

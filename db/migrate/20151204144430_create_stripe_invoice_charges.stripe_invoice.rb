# This migration comes from stripe_invoice (originally 20140605194026)
# GJS, consolidated all migrations to allow changes (e.g. remove :id)
class CreateStripeInvoiceCharges < ActiveRecord::Migration
  def change
    create_table :stripe_invoice_charges, :force => true do |t|
      t.integer :owner_id
      t.string  :stripe_id
      t.string  :stripe_refund_id
      t.integer :parent_invoice_id
      t.string  :invoice_number
      t.integer :date
      t.integer :amount, :default => 0
      t.string  :currency
      t.integer :total
      t.integer :subtotal
      t.integer :discount
      t.integer :period_start
      t.integer :period_end
      t.text    :charge_json
      t.text    :invoice_json
      t.timestamps
    end
  end
end

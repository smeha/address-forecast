class CreateForecasts < ActiveRecord::Migration[7.1]
  def up
    create_table :forecasts do |t|
      t.string :zip_code, limit: 10, null: false, comment: 'ZIP Code with in mind for other countries than USA in future'
      t.integer :current_temp, null: false, comment: 'Current Temperature at the time of the request'
      t.integer :high_temp, null: false, comment: 'Highes Temperature at the time of the request'
      t.integer :low_temp, null: false, comment: 'Lowest Temperature at the time of the request'
      t.timestamps
    end

    add_index :forecasts, :zip_code, unique: true
  end

  def down
    remove_index :forecasts, :zip_code
    drop_table :forecasts, if_exists: true
  end
end

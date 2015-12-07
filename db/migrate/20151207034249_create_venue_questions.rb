class CreateVenueQuestions < ActiveRecord::Migration
  def change
    create_table :venue_questions do |t|
    	t.references :venue, index: true
    	t.text :question
    	t.references :user, index: true
    	t.integer :num_comments, :default => 0

    	t.timestamps
    end
  end
end

class CreateVenueQuestionComments < ActiveRecord::Migration
  def change
    create_table :venue_question_comments do |t|
    	t.references :venue_question, index: true
    	t.text :comment
    	t.references :user, index: true

    	t.timestamps    	
    end
  end
end

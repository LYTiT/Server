class AddFromLocationToVeuneQuestionComments < ActiveRecord::Migration
  def change
  	add_column :venue_question_comments, :from_location, :boolean
  end
end

require 'spec_helper'

describe Api::V1::FeaturedController do

  describe "GET 'today'" do
    it "returns http success" do
      get 'today'
      response.should be_success
    end
  end

end

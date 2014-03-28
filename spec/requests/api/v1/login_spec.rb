require 'spec_helper'

describe 'Login API' do
  describe :login do
    let(:email) { 'foo@example.com' }
    let(:password) { 'foobar' }

    it 'should be able to login' do
      user = User.create(email: email, password: password)

      post api_v1_sessions_path, { email: email, password: password }

      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
      expect(json['name']).to eq(user.name)
      expect(json['email']).to eq(user.email)
    end
  end
end

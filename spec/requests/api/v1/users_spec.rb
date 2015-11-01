require 'spec_helper'

describe 'Users API' do
  describe :create do
    let(:params) { { name: 'name',
                     email: 'foo@example.com',
                     password: 'foobar'}}
    it 'should be able to create' do
      expect(User.count).to eq(0)

      post api_v1_users_path, params

      user = User.first
      expect(User.count).to eq(1)
      expect(user.email).to eq('foo@example.com')

      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
      expect(json['name']).to eq(user.name)
      expect(json['email']).to eq(user.email)
    end
  end
end

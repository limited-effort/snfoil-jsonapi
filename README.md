# Snfoil::Policy

![build](https://github.com/limited-effort/snfoil-policy/actions/workflows/main.yml/badge.svg) [![maintainability](https://api.codeclimate.com/v1/badges/81c3abdb068a2305d4ce/maintainability)](https://codeclimate.com/github/limited-effort/snfoil-policy/maintainability)

SnFoil Policies are an easy and intuitive way to build [Pundit](https://github.com/varvet/pundit) style authorization files with a little extra base functionality added in.

While it isn't required you use [Pundit](https://github.com/varvet/pundit) with it, we highly recommend it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snfoil-policy'
```

## Usage

### Policies

SnFoil Policies are meant to be used just like Pundit policies except you can build the actions using a helper and some of the setup work has been done for you.

The entity being authorized (usually a User) is accessible via the `entity` instance variable.
And the record the entity is trying to work with is accessible as the `record` instance variable.

Use `permission` to start setting up some checks.

```ruby
require 'snfoil/policy'

class PostPolicy
  include SnFoil::Policy

  permission :create? do
    entity.archived_at.nil? && record.user_id == entity.id
  end

  permission :update? do
    entity.archived_at.nil? && record.user_id == entity.id
  end

  permission :destroy? do
    entity.archived_at.nil? &&
      (record.user_id == entity.id || entity.is_admin?)
  end
end
```

Those methods are now defined on the class and can be called.

```ruby
policy = PostPolicy.new(current_user, new_post)

policy.create? # => true
```

You can also pass method names instead of blocks to the helper to dry things up.

```ruby
require 'snfoil/policy'

class PostPolicy
  include SnFoil::Policy

  permission :create?, with: :active_and_owner?

  permission :update?, with: :active_and_owner?

  permission :destroy? do
    entity.archived_at.nil? &&
      (record.user_id == entity.id || entity.is_admin?)
  end

  def active_and_owner?
    entity.archived_at.nil? && record.user_id == entity.id
  end
end
```

This can also be used to directly alias already defined permissions.

```ruby
permission :create? do
  entity.archived_at.nil? && record.user_id == entity.id
end

permission :update?, with: :create?
```

For more complex authorization mechanisms where more than one type of entity can operate against a record, you can supply the type of entity to check against.

```ruby
permission :create?, User do
  entity.archived_at.nil? && record.user_id == entity.id
end

permission :create?, UltimateAccessToken do
  entity.expires_at > Time.current
end
```

And if for some reason you want to have type specific policies and a default, you can do that too.  Just remember to define them in the order of most specific at the top, to most generic at the bottom.  SnFoil Policies will stop at the first matching policy.

```ruby
permission :create?, UltimateAccessToken do
  entity.expires_at > Time.current
end

permission :create? do
  entity.archived_at.nil? && record.user_id == entity.id
end

```

### Scope

There is nothing special about SnFoil Policy Scopes.  They are just defined to make life a little easier. Check out how to use Scopes in [Pundit](https://github.com/varvet/pundit#scopes), we highly recommend them.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/limited-effort/snfoil-policy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/limited-effort/snfoil-policy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [Apache 2 License](https://opensource.org/licenses/Apache-2.0).

## Code of Conduct

Everyone interacting in the Snfoil::Policy project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/limited-effort/snfoil-policy/blob/main/CODE_OF_CONDUCT.md).

# Recommendation
Gem for tags, votes and recommendations.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'recommendation', git: 'https://github.com/CD2/recommendation-gem'
```

And then execute:
```bash
$ bundle
$ rake recommendation:install:migrations
$ rake db:migrate
```

Recommendation relies on Recommendation Documents, which are created for records as and when they are required.
These can be pre-created for all existing records by running:
```bash
$ rake recommendation:create_docs
```

## Basic Usage
Include the 'Recommendable' concern in all models that have tags or votes. For example, if you had a User model and an Article model, *both* should include Recommendable.

Recommendables may be given static tags using 'tag_with' and 'remove_tag':

```ruby
Article.first.tag_with(:sports, :football)
Article.first.tags
# => [{"name" => "sports", "weight" => 1}, {"name" => "football", "weight" => 1}]

User.first.tag_with(:football, sports: 5)
User.first.tags
# => [{"name" => "football", "weight" => 1}, {"name" => "sports", "weight" => 5}]

User.first.remove_tag(:sports)
User.first.tags
# => [{"name" => "sports", "weight" => 1}]
```

Recommendables may acquire tags dynamically through voting:

```ruby
Article.first.tag_with(:sports)

User.first.vote_up(Article.first)
User.first.tags
# => [{"name" => "sports", "weight" => 1}]

User.first.vote_down(Article.first)
User.first.tags
# => [{"name" => "sports", "weight" => -1}]

User.first.unvote(Article.first)
User.first.tags
# => []
```

Recommendables can be recommended using 'recommend_to':

```ruby
Article.first.tag_with(:football, :cricket)
Article.second.tag_with(:basketball)
Article.third.tag_with(:cricket)

User.first.tag_with(basketball: 2, football: 1)

Article.recommend_to(User.first)
# => #<ActiveRecord::Relation [#<Article id: 2>, #<Article id: 1>, #<Article id: 3>]>

Article.recommend_to(Article.first)
# => #<ActiveRecord::Relation [#<Article id: 3>, #<Article id: 2>]>
```

# recommendables table has a single json field for tags [:static_tags, :tags_cache] and a polymorphic recommendable (either people or articles!)
# maybe table should have lat/long too?

# tags are calculated from the postgres version of:
user.tags = user.static_tags
Article.all.each do |article|
  article.tags.each do |tag|
    user.tags[tag] += article.votes.where(user: user) * Article.vote_weight
  end
end

# tags are RARELY re-calculated, instead relying on incremental changes to the cache

user.static_tags = { C: 3 }
user.tags
# => { C: 3 }

article1.static_tags = { A: 1, B: 1 }
article1.tags
# => { A: 1, B: 1 }

user.votes_up(article1)
user.tags
# => { A: 1, B: 1, C: 3 }

article2.tags = %i[B C]
article2.tags # => { B: 1, C: 1 }

user.votes_up(article2)
user.tags
# => { A: 1, B: 2, C: 4 }

article3.tags = { A: 1, B: 1 }
user.interest_in(article3)
# => 1 + 2 => 3

another_article.tags = { A: 1, C: 1 }
user.interest_in(another_article)
# => 1 + 4 => 5

# postgres version of
def thing.timeliness_modifier
  1 / thing.age # more complex than this, but it'll be 0-1(ish) and get smaller over time
end

# postgres version of
def user.location_modifier(thing)
  1 / distance_between(user, thing) # more complex than this, but it'll be 0-1(ish) and get smaller over larger distances
end

module Recommendable
  def self.recommended ; end
  def timeliness_modifier ; end

  def interests ; end
  def location_modifier ; end
end

class Article
  include Recommendable
  vote_weight 5
  default_tags { article_like: 1 }
end

class Person
  include Recommendable
  default_tags { cool_stuff: 10 }
end

Article.where.not(downvoted_by(person)).recommend_to Person.first

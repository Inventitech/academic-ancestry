require 'rubygems'
require 'bundler/setup'
require 'nokogiri'
require 'nikkou'
require 'open-uri'
require 'ruby-graphviz'

class Person
  attr_reader :advisors

  def initialize(name, nationality, year)
    @name = name
    @nationality = nationality
    @year = year
    @advisors = Array.new
  end

  def add_advisor(name)
    @advisors.push(name)
  end

  def ==(o)
    o.class == self.class && o.state == state
  end

  def to_s
    print_string = "#{@name}"
    print_string += ", #{@year}" unless @year.blank?
    print_string += " (#{@nationality})" unless @nationality.blank?
    print_string
  end

  alias_method :eql?, :==

  def hash
    state.hash
  end

  protected

  def state
    [@name]
  end
end

BASE_URL = "https://www.genealogy.math.ndsu.nodak.edu/"

@persons = Set.new

def traverse_person(url)
  puts "Opening #{url} ..."

  page = Nokogiri::HTML(open("#{BASE_URL}#{url}"))

  name = page.css('h2').first.content.strip.gsub(/ +/, ' ')
  puts name
  begin
    countries = page.css('div#paddingWrapper img')
    country = countries.flat_map { |c| c["title"] }.uniq.map { |c| c.gsub(/([A-Z])/, ' \\1').strip }.join(', ')
  rescue
  end
  begin
    year = page.css('div#paddingWrapper div').text.scan(/\d\d\d\d*/).first
  rescue
  end
  advisors = page.search('p').text_includes('Advisor')

  p = Person.new(name, country, year)
  return p if @persons.include? p
  @persons.add p

  advisors.css('a').select { |a|
    !a.nil?
  }.each { |a|
    p.add_advisor(traverse_person(a['href']))
  }

  p
end

def create_dot start_person
  g = GraphViz.new(:G, :type => :digraph)
  @persons.each { |p|
    g.add_nodes(p.to_s)
  }
  add_edges start_person, g
  g.output(:pdf => "academic_ancestry.pdf")
  g.output(:png => "academic_ancestry.png")
  g.output(:dot => "academic_ancestry.dot")
end

def add_edges(p, g)
  begin
    p.advisors.each { |a|
      if a.nil?
        return
      end
      g.add_edges(a.to_s, p.to_s)
      add_edges a, g
    }
  rescue
    puts p
  end
end

'''Create a graph and add one new student (not yet in the database). Handy for new students who are not yet in the database.'''
def create_ancestry_graph_add_leave_student(new_student, url1, url2)
  # A way to insert onself when not yet in the database (with two supervisors)
  advisor1 = traverse_person(url1)
  advisor2 = traverse_person(url2)
  new_student.add_advisor(advisor1)
  new_student.add_advisor(advisor2)
  @persons.add new_student
  create_dot new_student
end

'''Create a graph starting off from an existing record'''
def create_ancestry_graph (url)
  create_dot traverse_person(url)
end


# Sample call for new PhD students:
#create_ancestry_graph_add_leave_student(Person.new('Moritz Beller', 'Netherlands', '2017'), 'id.php?id=71273', 'id.php?id=134422')

# Sample call for
create_ancestry_graph "id.php?id=125302"

class Proposal
  attr_reader :value, :round
  attr_accessor :count

  def initialize(value, round)
    @value = value
    @round = round
    @count = 1
  end
end

class Node
  attr_reader :id
  attr_accessor :neighbors, :status, :entries, :node_count

  @@node_count = 0

  def initialize(id, status = nil)
    @id = id
    @neighbors = []
    @status = status
    @entries = []

    @@node_count += 1
  end

  def add_neighbor(node)
    @neighbors << node unless @neighbors.include?(node)
    node.neighbors << self unless node.neighbors.include?(self)
  end

  def propose(proposal)
    @status = (proposal)
    @neighbors.each { |node| node.receive(proposal) }
    
    @entries << "Proposed value: #{proposal.value}"

    if (@status.count >= (@@node_count / 2).ceil)
      reach_consensus(proposal, *@neighbors, self)
    else
      fail_to_reach_consensus(*@neighbors, self)
    end
  end

  def receive(proposal)
    if @status.nil? || @status.round < proposal.round
      @status = proposal
      proposal.count += 1
      @entries << "Accepted value: #{proposal.value}"
    else
      @entries << "Rejected value: #{proposal.value}"
    end
  end

  def log
    puts "NODE: #{@id}"
    entries.each { |entry| puts(entry) }
    puts
  end

  private

  def reach_consensus(proposal, *nodes)
    nodes.each { |node| node.entries << "Reached consensus on value: #{proposal.value}" }
  end

  def fail_to_reach_consensus(*nodes)
    nodes.each { |node| node.entries << "Failed to reach a consensus" }
  end
end

puts "----- CASE 1 -----"
puts

# Initialize 3 Nodes
node1 = Node.new(1)
node2 = Node.new(2)
node3 = Node.new(3)

# Turn them into neigbor nodes
node1.add_neighbor(node2)
node1.add_neighbor(node3)
node2.add_neighbor(node3)

# Make proposal from node1
node1.propose(Proposal.new('burgers', 1))

# Display the Nodes logs
node1.log
node2.log
node3.log

puts "----- CASE 2 -----"
puts

# Initialize a Proposal
pizza = Proposal.new('pizza', 3)

# Initialize 4 Nodes
node4 = Node.new(4)
node5 = Node.new(5)
node6 = Node.new(6, pizza) # Simulate a later rejection by giving an initial status to `node6`
node7 = Node.new(7, pizza) # Simulate a later rjection by giving an initial status to `node7`

# Turn them into neighboring Nodes
node4.add_neighbor(node5)
node4.add_neighbor(node6)
node4.add_neighbor(node7)
node5.add_neighbor(node6)
node5.add_neighbor(node7)
node6.add_neighbor(node7)

# Make proposal from `node5`, not reaching consensus
node5.propose(Proposal.new('lasagna', 2))

# Make proposal from `node4`, reaching consensus
node4.propose(Proposal.new('carbonara', 4))

# Display Nodes' logs
node4.log
node5.log
node6.log
node7.log

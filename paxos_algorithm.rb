class Paxos
  def initialize
    @nodes = []
  end

  def add_node(node)
    @nodes << node

    update_node_count
  end

  private

  def update_node_count
    Node.class_variable_set(:@@node_count, @nodes.length)
  end
end

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
  attr_accessor :neighbors, :accepted_status, :entries, :node_count

  @@node_count = 0

  def initialize(id, status = nil)
    @id = id
    @neighbors = []
    @promised_status = nil
    @accepted_status = nil
    @entries = []
  end

  def add_neighbor(node)
    @neighbors << node unless @neighbors.include?(node)
    node.neighbors << self unless node.neighbors.include?(self)
  end

  def propose(proposal)
    @promised_status = (proposal)
    @entries << "Proposed value: #{proposal.value}"

    promised = 1
    accepted = 1

    @neighbors.each do |node|
      promised += 1 if node.receive_proposal?(proposal, self)
    end

    unless @accepted_status.nil?
      reach_consensus(@accepted_status, self)
      return
    end

    if promised <= @@node_count / 2
      fail_to_reach_consensus(self)
    else
      @neighbors.each do |node|
        accepted += 1 if node.receive_accept?(proposal, self)
      end
    end

    if accepted <= @@node_count / 2
      fail_to_reach_consensus(proposal, self, *@neighbors)
    else
      reach_consensus(proposal, self, *@neighbors)
    end
  end

  def receive_proposal?(proposal, proposer)
    if @accepted_status && @accepted_status.round < proposal.round
      @entries << "Prepared for value: #{proposal.value}, but already accepted value: #{@accepted_status.value}"
      proposer.accepted_status = @accepted_status
      return true
    elsif @promised_status.nil? || @promised_status.round < proposal.round
      @promised_status = proposal

      @entries << "Sent promise to Node #{proposer.id} for value: #{proposal.value}"
      return true
    end

    return false
  end

  def receive_accept?(proposal, proposer)
    if @promised_status.value == proposal.value || @accepted_status.round < proposal.round
      @accepted_status = proposal
      @entries << "Sent accept to Node #{proposer.id} for value: #{proposal.value}"
      return true
    end
  end

  def log
    puts "NODE: #{@id}"
    entries.each { |entry| puts(entry) }
    puts
  end

  def simulate_partition(node)
    @neighbors.delete(node)
    node.neighbors.delete(self)
  end

  private

  def reach_consensus(proposal, *nodes)
    nodes.each { |node| node.entries << "Reached consensus on value: #{proposal.value}" }
  end

  def fail_to_reach_consensus(proposal, *nodes)
    nodes.each { |node| node.entries << "Failed to reach a consensus on value: #{proposal.value}" }
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

# Include nodes in first Paxos instance

case1 = Paxos.new

case1.add_node(node1)
case1.add_node(node2)
case1.add_node(node3)

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

# Initialize 5 Nodes
node4 = Node.new(4)
node5 = Node.new(5)
node6 = Node.new(6)
node7 = Node.new(7)
node8 = Node.new(8)

# Turn them into neighboring Nodes
node4.add_neighbor(node5)
node4.add_neighbor(node6)
node4.add_neighbor(node7)
node4.add_neighbor(node8)
node5.add_neighbor(node6)
node5.add_neighbor(node7)
node5.add_neighbor(node8)
node6.add_neighbor(node7)
node6.add_neighbor(node8)
node7.add_neighbor(node8)

# simulate partition between `node4` and `node5`

node4.simulate_partition(node5)

# Simulate partition between `node5` and `node6`

node5.simulate_partition(node6)

# Include nodes in second Paxos instance

case2 = Paxos.new

case2.add_node(node4)
case2.add_node(node5)
case2.add_node(node6)
case2.add_node(node7)
case2.add_node(node8)

# Make proposal from `node4`, reaching consensus
node4.propose(Proposal.new('carbonara', 2))

# Make proposal from `node5`, but consensus is already reached
node5.propose(Proposal.new('lasagna', 3))

# Display Nodes' logs
node4.log
node5.log
node6.log
node7.log
node8.log

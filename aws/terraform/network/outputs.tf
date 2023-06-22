output "vpcid" {
  value = aws_vpc.vpc.id
}

output "control_plane_node_subnet1_id" {
  value = aws_subnet.control_plane_node1.id
}

output "control_plane_node_subnet2_id" {
  value = aws_subnet.control_plane_node2[*].id
}

output "control_plane_node_subnet3_id" {
  value = aws_subnet.control_plane_node3[*].id
}

output "computenode_subnet1_id" {
  value = aws_subnet.computenode1.id
}

output "computenode_subnet2_id" {
  value = aws_subnet.computenode2[*].id
}

output "computenode_subnet3_id" {
  value = aws_subnet.computenode3[*].id
}

// A generic 2D Binary Space Partition (BSP) Tree module.
// This module provides a way to represent a 2D space that is recursively subdivided.

// The tree is polymorphic over two types:
// 1. Shape_Type - the type of primitive used for dividing the space.
//      This can be a Rect, a convex Polygon, or any other shape struct.
//      The user of this module MUST provide a 'contains_point' procedure for their Shape_Type:
//          contains_point :: (shape: Shape_Type, x: int, y: int) -> bool;
//
// 2. The type of the custom user data stored in each node.
//

Tree :: struct(Shape_Type: Type, Data_Type: Type)
{
    root:      *Node(Shape_Type, Data_Type);
    allocator: Allocator;
}

Node :: struct(Shape_Type: Type, Data_Type: Type)
{
    shape:  Shape_Type;
    data:   Data_Type;

    parent: *Node(Shape_Type, Data_Type);
    left:   *Node(Shape_Type, Data_Type);
    right:  *Node(Shape_Type, Data_Type);
}

init_tree :: (root_shape: $Shape_Type, root_data: $Data_Type, allocator := context.allocator) -> *Tree(Shape_Type, Data_Type) 
{
    tree := New(Tree(Shape_Type, Data_Type),, allocator);
    root := New(Node(Shape_Type, Data_Type),, allocator);

    root.shape = root_shape;
    root.data  = root_data;

    tree.root  = root;
    tree.allocator = allocator;
    return tree;
}

free_node_and_children :: (tree: *Tree, node: *Node)
{
    if !node return;

    free_node_and_children(tree, node.left);
    free_node_and_children(tree, node.right);
    defer free(node,, tree.allocator);

    // In case this is the root node.
    if !node.parent return;

    if node.parent.left == node node.parent.left = null;
    else if node.parent.right == node node.parent.right = null;
    return;
}

free_all_nodes :: (tree: *Tree)
{
    if !tree.root
    {
        log_error("Bad tree root = null.\n");
        return;
    }

    free_node_and_children(tree, tree.root);
    tree.root = null;
}

free_tree :: (tree: *Tree)
{
    if !tree
    {
        log_error("Bad tree = null.\n");
        return;
    }

    free_node_and_children(tree, tree.root);
    free(tree,, tree.allocator);
}

bisect_node :: (tree: *Tree, node: *$N/Node, left_shape: N.Shape_Type, left_data: N.Data_Type, right_shape: N.Shape_Type, right_data: N.Data_Type) -> bool
{
    if node.left || node.right
    {
        log_error("Bad bisect. Internal node instead of leaf.\n");
        return false;
    }

    left := New(N,, tree.allocator);
    left.shape = left_shape;
    left.data = left_data;
    left.parent = node;

    right := New(N,, tree.allocator);
    right.shape = right_shape;
    right.data = right_data;
    right.parent = node;

    node.left = left;
    node.right = right;

    return true;
}

// Provide a pointer to a resizeable array to get the full path to the leaf node (starting from root, leaf not included)
find_leaf_containing_point :: (using tree: *$T/Tree, x: $V, y: V, 
                      contains_point_proc: (T.Shape_Type, V, V) -> bool, 
                      path: *[..] type_of(T.root) = null) -> type_of(T.root)
{
    if !root
    {
        log_error("Bad root = null.\n");
        return null;
    }

    if !contains_point_proc(root.shape, x, y)
    {
        log_error("Bad point, not found in root.\n");
        return null;
    }

    curr := root;
    while curr.left
    {
        if path array_add(path, curr);

        if contains_point_proc(curr.left.shape, x, y)
            curr = curr.left;
        else if contains_point_proc(curr.right.shape, x, y)
            curr = curr.right;
        else break;
    }

    return curr;
}

#scope_module

#import "Basic";

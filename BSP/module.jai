// A generic 2D Binary Space Partition (BSP) Tree module.
// This module provides a way to represent a 2D space that is recursively subdivided.

// The tree is polymorphic over two types:
// 1. Shape_Type - the type of primitive used for dividing the space.
//      This can be a Rect, a convex Polygon, or any other shape struct.
//      The user of this module MUST provide a 'contains_point' procedure for their Shape_Type:
//          contains_point :: (shape: Shape_Type, x: int, y: int) -> bool;
//
// 2. The type of the custom user data stored in each node.

Numerical_Type :: float;

Node :: struct(Shape_Type: Type, T: Type)
{
    shape:  Shape_Type;
    data:   T;

    parent: *Node(Shape_Type, T);
    left:   *Node(Shape_Type, T);
    right:  *Node(Shape_Type, T);
}

Tree :: struct(Shape_Type: Type, T: Type)
{
    root:  *Node(Shape_Type, T);
    procs: Tree_Procs(Shape_Type);
}

Tree_Procs :: struct(Shape_Type: Type)
{
    contains_point: (Shape_Type, Numerical_Type, Numerical_Type) -> bool;
}

init_tree :: (root_shape: $Shape_Type, root_data: $T, procs: Tree_Procs) -> *Tree(Shape_Type, T) 
{
    tree := New(Tree(Shape_Type, T));
    root := New(Node(Shape_Type, T));

    root.shape = root_shape;
    root.data  = root_data;

    tree.root  = root;
    tree.procs = procs;

    return tree;
}

free_node_and_children :: (node: *Node)
{
    if !node return;

    free_node_and_children(node.left);
    free_node_and_children(node.right);
    defer free(node);

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

    free_node_and_children(tree.root);
    tree.root = null;
}

free_tree :: (tree: *Tree)
{
    if !tree
    {
        log_error("Bad tree = null.\n");
        return;
    }

    free_node_and_children(tree.root);
    free(tree);
}

bisect_node :: (node: *Node($Shape_Type, $T), left_shape: Shape_Type, left_data: T, right_shape: Shape_Type, right_data: T) -> bool
{
    if node.left || node.right
    {
        log_error("Bad bisect. Internal node instead of leaf.\n");
        return false;
    }

    left := New(Node(Shape_Type, T));
    left.shape = left_shape;
    left.data = left_data;
    left.parent = node;

    right := New(Node(Shape_Type, T));
    right.shape = right_shape;
    right.data = right_data;
    right.parent = node;

    node.left = left;
    node.right = right;

    return true;
}

// Provide a pointer to a resizeable array to get the full path to the leaf node (starting from root, leaf not included)
find_leaf_at_point :: (tree: *Tree($Shape_Type, $T), x: Numerical_Type, y: Numerical_Type, path: *[..] *Node(Shape_Type, T) = null) -> *Node(Shape_Type, T)
{
    if !tree.root
    {
        log_error("Bad tree root = null.\n");
        return null;
    }

    if !tree.procs.contains_point(tree.root.shape, x, y)
    {
        log_error("Bad point, not found in root.\n");
        return null;
    }

    curr := tree.root;
    contains := tree.procs.contains_point;
    while curr.left
    {
        if path array_add(path, curr);

        if contains(curr.left.shape, x, y)
            curr = curr.left;
        else if contains(curr.right.shape, x, y)
            curr = curr.right;
        else break;
    }

    return curr;
}

#scope_module

#import "Basic";

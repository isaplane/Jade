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
#module_parameters(
    SHAPE_TYPE:     Type,
    DATA_TYPE:      Type,
    NUMERICAL_TYPE: Type
);

Node :: struct
{
    shape:  SHAPE_TYPE;
    data:   DATA_TYPE;

    parent: *Node;
    left:   *Node;
    right:  *Node;
}

Tree :: struct
{
    root:  *Node;
    procs: Tree_Procs;
}

Tree_Procs :: struct
{
    contains_point: (SHAPE_TYPE, NUMERICAL_TYPE, NUMERICAL_TYPE) -> bool;
}

init_tree :: (root_shape: SHAPE_TYPE, root_data: DATA_TYPE, procs: Tree_Procs) -> *Tree 
{
    tree := New(Tree);
    root := New(Node);

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

bisect_node :: (node: *Node, left_shape: SHAPE_TYPE, left_data: DATA_TYPE, right_shape: SHAPE_TYPE, right_data: DATA_TYPE) -> bool
{
    if node.left || node.right
    {
        log_error("Bad bisect. Internal node instead of leaf.\n");
        return false;
    }

    left := New(Node);
    left.shape = left_shape;
    left.data = left_data;
    left.parent = node;

    right := New(Node);
    right.shape = right_shape;
    right.data = right_data;
    right.parent = node;

    node.left = left;
    node.right = right;

    return true;
}

// Provide a pointer to a resizeable array to get the full path to the leaf node (starting from root, leaf not included)
find_leaf_at_point :: (tree: *Tree, x: NUMERICAL_TYPE, y: NUMERICAL_TYPE, path: *[..] *Node = null) -> *Node
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

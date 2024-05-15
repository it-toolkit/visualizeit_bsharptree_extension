# B-\# Tree Extension

This is the B-\# Tree extension usage doc.

## Available commands

### bsharptree-create

Creates an empty tree with the given maximum capacity. As an optional feature you can pass the values to initialize the tree.

### bsharptree-insert

Inserts the given value into the tree.

### bsharptree-remove

Removes the given value from the tree, if found.

### bsharptree-find

Return the node id where the given value should be located.

#### Usage example

```
name: "..."
description: "..."
tags: ["..."]
scenes:
  - name: "..."
    extensions: ['bsharp-tree-extension']
    description: "..."
    initial-state:
      - bsharptree-create: [3, [12, 15, 28, 33, 66]]
    transitions:
      - bsharptree-insert: [128]
      - bsharptree-find: [33]
      - bsharptree-remove: [15]
```
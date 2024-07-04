# B\# Tree Extension

This is the B\# Tree extension usage doc.

Extension id: `bsharptree`

## Available commands

### bsharptree-create

Creates an empty tree with the given maximum capacity. As an optional feature you can pass the values to initialize the tree.

| Name            | Type     | Position | Required | Default value | Description                          |
|-----------------|----------|----------|----------|---------------|--------------------------------------|
| maxCapacity     | int      | 0        | true     | -             | Must be in range [ 3 , 10 ]          |
| initialValues   | intArray | 1        | true     | -             | Values must be in range [ 1 , 9999 ] |
| autoIncremental | boolean  | 2        | false    | false         | -                                    |

### bsharptree-insert

Inserts the given value into the tree.

| Name  | Type | Position | Required | Default value | Description                   |
|-------|------|----------|----------|---------------|-------------------------------|
| value | int  | 0        | true     | -             | must be in range [ 1 , 9999 ] |

### bsharptree-remove

Removes the given value from the tree, if found.

| Name  | Type | Position | Required | Default value | Description                   |
|-------|------|----------|----------|---------------|-------------------------------|
| value | int  | 0        | true     | -             | must be in range [ 1 , 9999 ] |

### bsharptree-find

Return the node id where the given value should be located.

| Name  | Type | Position | Required | Default value | Description                   |
|-------|------|----------|----------|---------------|-------------------------------|
| value | int  | 0        | true     | -             | must be in range [ 1 , 9999 ] |

#### Usage example

```yaml
name: "..."
description: "..."
scenes:
  - name: "..."
    extensions: ['bsharptree']
    description: "..."
    initial-state:
      - bsharptree-create:
          maxCapacity: 3,
          initialValues: [12, 15, 28, 33, 66]
    transitions:
      - bsharptree-insert: 128
      - bsharptree-find: 33
      - bsharptree-remove: 15
```
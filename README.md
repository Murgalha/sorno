# Sorno

## About
Sorno is a sync utility that lets you semantically organize directories and
back them up locally or on a remote server.

In its current state, Sorno uses sqlite3 database to manage directories and `rsync`
to effectively copy your data.

### Concepts
#### Target
A destination to where copy the files to.

| Field name  | Description                                                             | sqlite        |
|-------------|-------------------------------------------------------------------------|---------------|
| **Name**    | A string to represent the destination                                   | TEXT PK       |
| **Address** | The address of the machine to send data (only used if target is remote) | TEXT          |
| **User**    | Username to connect on remote machine (only used if target is remote)   | TEXT          |
| **Path**    | A base path to copy your data to (e.g. `/data/backup/`)                 | TEXT NOT NULL |

#### Element
A Directory containing data. Can only be part of a single profile (or none, but then it has no use).

| Field name      | Description                                                | sqlite        |
|-----------------|------------------------------------------------------------|---------------|
| **Name**        | A string to represent the directory                        | TEXT PK       |
| **Source**      | Absolute path of the directory on local machine            | TEXT NOT NULL |
| **Destination** | Relative path on **target** (will be appended with `path`) | TEXT          |

Note: If the element destination is empty, it will default to the basename of `source`.

#### Profile
A semantically organized group of directories.

| Field name | Description                       | sqlite  |
|------------|-----------------------------------|---------|
| **Name**   | A string to represent the profile | TEXT PK |

The `profile` table itself only contains a name, but there is the `profileelements` table
that connects multiple elements to a profile.

| Field name  | Description         | sqlite     |
|-------------|---------------------|------------|
| **Profile** | Name of the profile | TEXT FK PK |
| **Element** | Name of the element | TEXT FK PK |

Using the interface, it is possible to create profiles, targets and elements, and link the latter to profiles
To sync the data, chose a profile and a target, and the data will be copied using `rsync`.

#### File Structure
The data is copied from the absolute path on the local machine to the path on the target,
similar to the structure below.
```
<target-path>/
├─ <profile 1>/
│  ├─ <element 1>/
│  ├─ <element 2>/
├─ <profile 2>/
│  ├─ <element 3>/
│  ├─ <element 4>/
```

## Compile and Install
For compilation, one need to have sqlite3 headers and a C compiler (and preferably `make`).
Then, simply run:
```
make
make run
```

## Example
Suppose I am on a Linux machine and want to backup my Documents and Pictures,
syncing it on a remote local server at 192.168.15.15. The required steps to do so is as follows
(The names are for clarification purposes, you can use whichever name you want):

1. Create a profile named `home`
2. Create a target named `localserver` and set:
   - Address to `192.168.15.15`
   - User to `servermaster`
   - Path to `/data/`
3. Create an element named `Documents` with source `/home/user/Documents`
4. Create an element named `Pictures` with source `/home/user/Pictures`
5. Link both created elements to the `home` profile.
6. Sync `home`to `localserver`

After the sync is finished, the localserver will look like this:
```
/data/
├─ home/
│  ├─ Documents/
│  ├─ Pictures/
```

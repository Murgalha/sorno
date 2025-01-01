pub const CREATE_PROFILE_TABLE =
    \\CREATE TABLE IF NOT EXISTS profile(
    ++
    \\id INTEGER PRIMARY KEY AUTOINCREMENT,
    ++
    \\name TEXT UNIQUE NOT NULL);
;

pub const CREATE_TARGET_TABLE =
    \\CREATE TABLE IF NOT EXISTS target(
    ++
    \\id INTEGER PRIMARY KEY AUTOINCREMENT,
    ++
    \\name TEXT UNIQUE NOT NULL,
    ++
    \\path TEXT NOT NULL,
    ++
    \\address TEXT,
    ++
    \\user TEXT);
;

pub const CREATE_ELEMENT_TABLE =
    \\CREATE TABLE IF NOT EXISTS element(
    ++
    \\id INTEGER PRIMARY KEY AUTOINCREMENT,
    ++
    \\name TEXT UNIQUE NOT NULL,
    ++
    \\source TEXT NOT NULL,
    ++
    \\destination TEXT NOT NULL);
;

pub const CREATE_PROFILEELEMENTS_TABLE =
    \\CREATE TABLE IF NOT EXISTS profileelements(
    ++
    \\profile_id INTEGER NOT NULL,
    ++
    \\element_id INTEGER NOT NULL,
    ++
    \\FOREIGN KEY(profile_id) REFERENCES profile(id),
    ++
    \\FOREIGN KEY(element_id) REFERENCES element(id),
    ++
    \\PRIMARY KEY(profile_id, element_id));
;

pub const SELECT_ALL_TARGETS =
    \\SELECT id, name, path, user, address FROM target;
;

pub const SELECT_ALL_PROFILE_NAMES =
    \\SELECT id, name FROM profile;
;

pub const SELECT_FULL_PROFILE =
    \\SELECT p.id as profile_id, p.name as profile_name, e.id as element_id,
    ++
    \\ e.name as element_name, e.source as element_source, e.destination as element_destination
    ++
    \\ FROM profile p JOIN profileelements pe ON p.id = pe.profile_id
    ++
    \\ JOIN element e ON e.id = pe.element_id WHERE p.name = ?;
;

pub const SELECT_UNLINKED_ELEMENTS =
    \\SELECT id, name, source, destination FROM element WHERE id NOT IN(SELECT element_id FROM profileelements);
;

pub const INSERT_PROFILE =
    \\INSERT INTO profile(name) VALUES(?);
;

pub const INSERT_ELEMENT =
    \\INSERT INTO element(name, source, destination) VALUES(?, ?, ?);
;

pub const INSERT_TARGET =
    \\INSERT INTO target(name, path, address, user) VALUES(?, ?, ?, ?);
;

pub const INSERT_PROFILEELEMENT =
    \\INSERT INTO profileelements(profile_id, element_id) VALUES(?, ?);
;

package dic

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

type dic struct {
	db *sql.DB
}

func New(name string) *dic {
	ins := &dic{}
	db, err := sql.Open("sqlite3", name)
	if err != nil {
		log.Fatalln(err)
	}
	sqlStmt := `create table if not exists dic (cn bold not null primary key, trans bold not null);`
	_, err = db.Exec(sqlStmt)
	if err != nil {
		log.Fatalln(err)
	}
	ins.db = db
	return ins
}

func (d *dic) Close() {
	if d.db != nil {
		if err := d.db.Close(); err != nil {
			log.Fatalln(err)
		}
		d.db = nil
	}
}

func (d *dic) Insert(cn, trans []byte) error {
	tx, err := d.db.Begin()
	if err != nil {
		return err
	}
	stmt, err := tx.Prepare("insert or ignore into dic(cn, trans) values(?, ?)")
	if err != nil {
		return err
	}
	defer stmt.Close()
	_, err = stmt.Exec(cn, trans)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (d *dic) Query(text []byte) ([]byte, error) {
	var trans []byte
	stmt, err := d.db.Prepare("select trans from dic where cn = ?")
	if err != nil {
		return trans, err
	}
	defer stmt.Close()
	err = stmt.QueryRow(text).Scan(&trans)
	if err != nil {
		return trans, err
	}
	return trans, nil
}

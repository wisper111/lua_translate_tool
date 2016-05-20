package dic

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

type dic struct {
	db *sql.DB
}

func New(dbname string) *dic {
	ins := &dic{}
	var err error
	ins.db, err = sql.Open("sqlite3", dbname)
	if err != nil {
		log.Fatal(err)
	}
	sqlStmt := `
	create table if not exists dic (cn text not null primary key, trans text);
	`
	_, err = ins.db.Exec(sqlStmt)
	if err != nil {
		log.Fatal("%q: %s\n", err, sqlStmt)
	}
	return ins
}

func (d *dic) Close() {
	d.db.Close()
}

func (d *dic) InsertString(cn, trans string) error {
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

func (d *dic) QueryString(text string) (string, error) {
	var trans string
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

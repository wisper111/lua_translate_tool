package dic

import (
	"database/sql"
	"log"
	"sync"

	_ "github.com/mattn/go-sqlite3"
)

type dic struct {
	db    *sql.DB
	count int
}

var instance *dic
var once sync.Once

func GetInstance(name string) *dic {
	once.Do(func() {
		instance = &dic{nil, 0}
	})
	instance.InitDic(name)
	return instance
}

func (d *dic) InitDic(name string) {
	if d.count > 0 {
		d.count++
		return
	}
	db, err := sql.Open("sqlite3", name)
	if err != nil {
		log.Fatalln(err)
	}
	sqlStmt := `
	create table if not exists dic (cn bold not null primary key, trans bold not null);
	`
	_, err = db.Exec(sqlStmt)
	if err != nil {
		log.Fatalln(err)
	}
	d.db = db
	d.count = 1
}

func (d *dic) Close() {
	d.count--
	if d.count <= 0 {
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

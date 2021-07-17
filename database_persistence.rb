require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "bookmarks")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def username_available?(username)
    # puts "In DatabasePersistence.username_available?. username = #{username}"

    sql = <<~SQL
      SELECT user_name FROM users WHERE user_name = $1
    SQL

    result = query(sql, username)
    # puts "In DatabasePersistence.username_available?. result.ntuples = #{result.ntuples}"
    result.ntuples == 0
  end

  def username_exists?(username)
    # puts "In DatabasePersistence.username_exists?. username = #{username}"

    sql = <<~SQL
      SELECT user_name FROM users WHERE user_name = $1
    SQL

    result = query(sql, username)
    # puts "In DatabasePersistence.username_exists?. result.ntuples = #{result.ntuples}"
    result.ntuples > 0
  end

  def store_new_username(username)
    # puts "In DatabasePersistence.store_new_username. username = #{username}"

    sql = <<~SQL
      INSERT INTO users(user_name) VALUES ($1);
    SQL

    result = query(sql, username)
    # puts "In DatabasePersistence.store_new_username. result.ntuples = #{result.ntuples}" 
  end

  def relate_user_and_url(username, url)
    # puts "In DatabasePersistence.relate_user_and_url. username = #{username}   url = #{url}"

    if !url_exists_in_site_table(url)
      # puts "In DatabasePersistence.relate_user_and_url. url does *not* yet exist in site table"
      insert_url_into_site_table(url)
    else
      # puts "In DatabasePersistence.relate_user_and_url. url *does* exist in site table"
    end

    user_id = get_user_id(username)
    site_id = get_site_id(url)

    if !id_pair_is_in_join_table(site_id, user_id)
      insert_ids_into_join_table(site_id, user_id)
    end
  end

  def url_exists_in_site_table(url)
    sql = <<~SQL
      SELECT site_name FROM sites WHERE site_name = $1;
    SQL

    result = query(sql, url)

    result.ntuples > 0
  end

  def get_user_id(username)
    sql = <<~SQL
      SELECT id FROM users WHERE user_name = $1
    SQL

    result = query(sql, username)

    tuple = result.first

    tuple["id"]
  end  
  
  def get_site_id(url)
    sql = <<~SQL
      SELECT id FROM sites WHERE site_name = $1
    SQL

    result = query(sql, url)

    tuple = result.first

    # puts "get_site_id. tuple[\"id\"] = #{tuple["id"]}"

    tuple["id"]
  end

  def id_pair_is_in_join_table(site_id, user_id)
    # puts "id_pair_is_in_join_table. site_id = #{site_id}  user_id = #{user_id}"

    sql = <<~SQL
      SELECT 1 FROM sites_users WHERE site_id = $1 AND user_id = $2
    SQL

    result = query(sql, site_id, user_id)
    result.ntuples > 0

  end

  def insert_ids_into_join_table(site_id, user_id)
    # puts "insert_ids_into_join_table. site_id = #{site_id}  user_id = #{user_id}"

    sql = <<~SQL
      INSERT INTO sites_users (site_id, user_id) VALUES ($1, $2)
    SQL

    result = query(sql, site_id, user_id)
  end


  def get_user_urls(username)
    # puts "In get_user_urls. username = #{username}"

    ret_hash = {}

    usr_id = get_user_id(username)
    # puts "In get_user_urls. usr_id = #{usr_id}"


    sql = <<~SQL
      SELECT id, site_name FROM sites 
      WHERE id IN (SELECT site_id FROM sites_users WHERE user_id = $1);   
    SQL

    result = query(sql, usr_id)

    # puts "In get_user_urls. result.values = #{result.values}"

    result.each do |tuple|
      # puts "In get_user_urls. tuple = #{tuple}"
      ret_hash[tuple["id"]] = tuple["site_name"]
    end
    ret_hash
  end

  def delete_account(username)

    usr_id = get_user_id(username)

    # Delete all entries in join table for this user id
    sql = <<~SQL
      DELETE FROM sites_users WHERE user_id = $1;
    SQL

    # puts "In delete_account. username = #{username}"

    result = query(sql, usr_id)

    # Delete all entries users table for this user id
    sql = <<~SQL
      DELETE FROM users WHERE id = $1;
    SQL

    result = query(sql, usr_id)    
    
    # Delete all entries in sites table for which there is no user associated (in join table)
    sql = <<~SQL
      DELETE FROM sites WHERE id NOT IN (SELECT site_id FROM sites_users);
    SQL

    result = query(sql)   
  end

  def delete_url(siteid, username)

    # puts "In delete_url. siteid = #{siteid}   username = #{username}"

    usr_id = get_user_id(username)

    # Delete all entries in join table for this url and user id
    sql = <<~SQL
      DELETE FROM sites_users WHERE site_id = $1 AND user_id = $2;
    SQL
    result = query(sql, siteid, usr_id)

    # Get deleted url (as far as this user is concerned) 
    sql = <<~SQL
      SELECT site_name FROM sites WHERE id = $1;
    SQL
    result = query(sql, siteid)
    tuple = result.first
    deleted_url = tuple["site_name"]

    # puts "In delete_url. deleted_url = #{deleted_url}"

    # Delete all entries in sites table for which there is no user associated (in join table)
    sql = <<~SQL
      DELETE FROM sites WHERE id NOT IN (SELECT site_id FROM sites_users);
    SQL
    result = query(sql)

    deleted_url
  end

  private

  def insert_url_into_site_table(url)
    # puts "In DatabasePersistence.insert_url_into_site_table  url = #{url}"

    sql = <<~SQL
      INSERT INTO sites (site_name) VALUES ($1);
    SQL

    result = query(sql, url)
  end
end

class AdminCompaniesController < ApplicationController
  def index
    #connect to db
    require 'pg'
    conn = PG::Connection.connect("localhost", 5432, "", "", "myapp_main", "postgres", "")
    
    jsonData = getJsonData()
    missingStreetsIds= getMissingStreetsIds(conn, jsonData)
    @dataListToDisplay = getListToDisplay(conn, missingStreetsIds)
  end



  private

  #parse JSON data from given links
  def getJsonData()
    parcedJSON = []
    require 'net/http'
    require 'json'
    i = 0;
    while i<3;
      uri = URI("https://syntask.herokuapp.com/streets#{i+1}.json")
      response = Net::HTTP.get(uri)
      parcedJSON[i] = JSON.parse(response.to_str)
      i += 1
    end
    return parcedJSON
  end

  #get streets that wasn't cleaned
  def getMissingStreetsIds(conn, *jsonData)
    #Get ids of all streets that was cleaned
    clearedStreets = []
    i=1
    conn.prepare('get_street',"SELECT id FROM streets WHERE name = $1")
    while i<4
      @json_street = jsonData[0][i-1]['streets']
      j=0
      while j<@json_street.length
        clearedStreets.push(conn.exec_prepared('get_street', [@json_street[j]]).values)
        j += 1
      end
      i += 1
    end
    #Get ids of all streets that wasn's provided as cleaned by any admin
    last_id = conn.exec('SELECT last_value FROM streets_id_seq FETCH FIRST ROW ONLY')[0].values[0].to_i
    i=1
    notCleaned = []
    while i <= last_id
      j=0
      isCleaned = false
      while j < clearedStreets.length
          if clearedStreets[j][0].include?(i.to_s)
            isCleaned = true
            break
          end
          j += 1
      end
      if  !isCleaned
        notCleaned.push(i)
      end
      i += 1
    end
    #retur array of streets that wasnt cleaned id's
    return notCleaned
  end

  #prepare list with data to display
  def getListToDisplay(conn, *missingStreets)
    #get not cleaned buildings numbers and administrators ids
    missingBuildings = []
    index = 0
    conn.prepare('get_buildings_by_street', "SELECT number, administrator_id FROM buildings WHERE street_id = $1")
    missingStreets[0].each do |missingStreetId|
      missingBuildings[index] = conn.exec_prepared('get_buildings_by_street', [missingStreetId]).values
      index += 1
    end
    #prepare array with all data to display
    conn.prepare('get_street_name', "SELECT name FROM streets WHERE id = $1")
    conn.prepare('get_admin_name', "SELECT name, phone FROM administrators WHERE id = $1")
    index=0
    dataToDisplay = []
    i = 0
    while i < missingStreets[0].length
      j = 0
      while j < missingBuildings[i].length
        streetName = conn.exec_prepared('get_street_name', [missingStreets[0][i]]).values
        adminName = conn.exec_prepared('get_admin_name', [missingBuildings[i][j][1]]).values
        dataToDisplay[index] = "" + streetName[0][0] + ", " + missingBuildings[i][j][0] + " - call your company " + adminName[0][0] +" (phone number: " + adminName[0][1] + ")"
        index += 1
        j += 1
      end
      i += 1
    end
    #return prepared data
    return dataToDisplay
  end


end

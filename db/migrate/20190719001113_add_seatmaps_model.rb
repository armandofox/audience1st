class AddSeatmapsModel < ActiveRecord::Migration
  def change
    create_table 'seatmaps', :force => :cascade do |t|
      t.string 'name', :null => false
      t.text 'csv', :null => true
      t.text 'json', :null => false
    end
    csv = get_csv
    map = Seatmap.new(:name => "Altarena default", :csv => get_csv)
    map.parse_csv_to_json
    map.save!
  end
  def get_csv
    return <<CSV1
,,,,,,D301,D302,D303,D304,,,D305,D306,D307,D308,,,,C412,C512,C614,.
A514,,,,,,D201,D202,D203,D204,,,D205,D206,D207,D208,,,,C411,C511,C613,.
A513,A411,,,,,,D101,D102,D103,,,D104,D105,D106,,,,,C410,C510,C612,.
A512,A410,A309,,,,,,,,,,,,,,,,,,,C611,.
A511,A409,A308,,,,,,,,,,,,,,,C208,C308,C409,C509,C610,.
A510,A408,A307,A207,A106,,,,,,,,,,,,C106,C207,C307,C408,C508,C609,.
A509,A407,A306,A206,A105,,,,,,,,,,,,C105,C206,C306,C407,C507,C608,.
A508,A406,A305,A205,A104,,,,,,,,,,,,C104,C205,C305,C406,C506,C607,.
A507,A405,A304,A204,A103,,,,,,,,,,,,C103,C204,C304,C405,C505,C606,.
A506,A404,A303,A203,A102,,,,,,,,,,,,C102,C203,C303,C404,C504,C605,.
A505,A403,A302,A202,A101,,,,,,,,,,,,C101,C202,C302,C403,C503,C604,.
A504,A402,A301,A201,,,,,,,,,,,,,,C201,C301,C402,C502,C603,.
A503,A401,,,,,,,,,,,,,,,,,,C401,C501,C602,.
A502,,,,,,B101,B102,B103,B104,B105,B106,B107,B108,B109,B110,,,,,,C601,.
A501,,,,B201,B202,B203,B204,B205,B206,B207,B208,B209,B210,B211,B212,B213,B214,,,,,.
,,B301,B302,B303,B304,B305,B306,B307,B308,,,,B309,B310,B311,B312,B313,B314,B315,,,.
CSV1
  end
end


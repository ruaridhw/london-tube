import networkx as nx
import psycopg2
import psycopg2.extras
from copy import deepcopy

conn = psycopg2.connect(host="localhost",database="londontubepython", user="postgres", password="mysecretpassword")
cur = conn.cursor('server_side_cursor', cursor_factory=psycopg2.extras.DictCursor)

sqlquery = ('SELECT * FROM departures '
            'ORDER BY "From_StopPointName", "DepartureMins_Link", "VehicleJourneyCode" ')

cur.execute(sqlquery)

#   NodeID: VehicleJourneyCode + From_StopPointRef
#   NodeData: VehicleJourneyCode, FromStopPointName, ToStopPointName, DepartureMins_Link, ArrivalMins_Link, JourneyTime

#   EdgeData: Type = ['Travel' or 'Wait'], Cost = [JourneyTime or DepartureMins_Link(Dep2) - DepartureMins_Link(Dep1)]

## TODO Add line information

## TODO for earliest arrival, culminate all arrival nodes into a single station using station name
##      for latest departure, culminate all departure nodes into a single station using station name

G = nx.DiGraph()

prev_row = None
for row in cur:

    # Add or update node data
    G.add_node(row['VehicleJourneyCode'] + '//' + row['From_StopPointRef'],
               VehicleJourneyCode = row['VehicleJourneyCode'],
               #FromStopPointName = row['FromStopPointName'],
               #ToStopPointName = row['ToStopPointName'],
               #DepartureMins_Link = row['DepartureMins_Link'],
               #ArrivalMins_Link = row['ArrivalMins_Link'],
               #JourneyTime = row['JourneyTime'],

               StopPointName = row['From_StopPointName'],
               MinuteOfDay = row['DepartureMins_Link']
              )

    if row['Flag_LastStop'] == True:
        G.add_node(row['VehicleJourneyCode'] + '//' + row['To_StopPointRef'],
               VehicleJourneyCode = row['VehicleJourneyCode'],
               StopPointName = row['To_StopPointName'],
               MinuteOfDay = row['ArrivalMins_Link']
              )

    # Create new Travel edge from row
    G.add_edge(row['VehicleJourneyCode'] + '//' + row['From_StopPointRef'],
               row['VehicleJourneyCode'] + '//' + row['To_StopPointRef'],
               mvt_type = 'travel',
               cost = row['JourneyTime'])

    # Create new Waiting edge from previous row if it's the same station
    if prev_row is not None and prev_row['From_StopPointName'] == row['From_StopPointName']:
        G.add_edge(prev_row['VehicleJourneyCode'] + '//' + prev_row['From_StopPointRef'],
                   row['VehicleJourneyCode'] + '//' + row['From_StopPointRef'],
                   mvt_type = 'wait',
                   cost = row['DepartureMins_Link'] - prev_row['DepartureMins_Link'])

    prev_row = deepcopy(row)


cur.close()
conn.close()
print('Database connection closed.')

_DEBUG_ = False

if _DEBUG_:
    for node, data in G.nodes(data=True):
        if 'StopPointName' not in data:
            print('Broken node: ' + node)


H = G.copy() #TODO cleverly make this a subgraph based on query instead of full copy
#G.remove_node(query_node)


path_query = {
    'From_StopPointName': 'Bank',
    'To_StopPointName': 'Victoria',
    'time': 9 * 60
}

H.add_node('Start', StopPointName = path_query['From_StopPointName'], MinuteOfDay = path_query['time'])
H.add_node('End', StopPointName = path_query['To_StopPointName'], MinuteOfDay = None)


## for earliest arrival, culminate all arrival nodes into a single station using station name
for n, n_data in H.nodes(data=True):

    # Cannot catch a train that has already left :(
    if n is not 'End' and n_data['MinuteOfDay'] >= path_query['time']:

        if path_query['From_StopPointName'] in n_data['StopPointName']: # Use exact match instead of "in"
            H.add_edge('Start', n, mvt_type = 'start', cost = n_data['MinuteOfDay'] - path_query['time'])

        if path_query['To_StopPointName'] in n_data['StopPointName']: # Use exact match instead of "in"
            H.add_edge(n, 'End', mvt_type = 'end', cost = 0)


for node in nx.shortest_path(H,
                 source='Start',
                 target='End',
                 weight='cost'):
    n_data = H.nodes(data=True)[node]
    print(n_data['StopPointName'], n_data['MinuteOfDay'])

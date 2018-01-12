#' ---
#' title: "Shortest Path"
#' ---

#' This file provides the algorithms implemented
#' in the Visualising Data notebook in order to
#' use as a standalone module.
#'
#' The NetworkX object for the Departures Board
#' query used in the notebook is also provided
#' to avoid having to setup a database and run
#' any preceding extraction code.
#'
#' Due to its size, this pickle object is kept
#' on a separate branch from master to keep
#' the master clone size small.
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/python/ShortestPath.py)

#+ shortestpath, engine='python'
import networkx as nx

example_path_query = {
    'From_StopPointName': 'Bank',
    'To_StopPointName': 'Victoria',
    'time': 9 * 60,
    'leave_after': True
}

def setup_shortest_path(path_query):
    """
        Add the Start and End nodes to the network for the given query
        Connect them to the departures and arrivals for the relevant stations
    """

    # For "Leave After" query, assign the leaving time to the start node
    # and leave arriving time as unknown
    if path_query['leave_after'] == True:

        H.add_node('Start', StopPointName = path_query['From_StopPointName'],
                   MinuteOfDay = path_query['time'], movement = 'Departure')

        H.add_node('End', StopPointName = path_query['To_StopPointName'],
                   MinuteOfDay = None, movement = 'Arrival')

    # For "Arrive Before" query, assign the arriving time to the end node
    # and leave departure time as unknown
    else:
        H.add_node('Start', StopPointName = path_query['From_StopPointName'],
                   MinuteOfDay = None, movement = 'Departure')

        H.add_node('End', StopPointName = path_query['To_StopPointName'],
                   MinuteOfDay = path_query['time'], movement = 'Arrival')

    for n, n_data in H.nodes(data=True):
        # Don't want to add an edge from 'Start' to 'End', 'End' to 'End' or 'Start' to 'Start'
        if n == 'Start' or n == 'End':
            continue

        if path_query['leave_after'] == True:
            # Cannot catch a train that has already left
            if n_data['MinuteOfDay'] >= path_query['time']:

                if path_query['From_StopPointName'] in n_data['StopPointName']:
                    H.add_edge('Start', n, movement = 'Start',
                               cost = n_data['MinuteOfDay'] - path_query['time'])

                if path_query['To_StopPointName'] in n_data['StopPointName']:
                    H.add_edge(n, 'End', movement = 'End',
                               cost = 0)
        else:

            # No point catching a train that leaves after we want to arrive
            if n_data['MinuteOfDay'] <= path_query['time']:

                if path_query['From_StopPointName'] in n_data['StopPointName']:
                    H.add_edge('Start', n, movement = 'Start',
                               cost = 0)

                if path_query['To_StopPointName'] in n_data['StopPointName']:
                    H.add_edge(n, 'End', movement = 'End',
                               cost = path_query['time'] - n_data['MinuteOfDay'])

def minutes_to_time(minutes_past_midnight):
    """
        Reformat a decimal 'minutes past midnight' to a time string rounded to the nearest second
    """
    hours, remainder = divmod(minutes_past_midnight * 60, 3600)
    minutes, seconds = divmod(remainder, 60)
    return '{:02.0f}:{:02.0f}:{:02.0f}'.format(hours, minutes, int(seconds))


def print_path(path):
    """
        Iterate through a journey's shortest path and print only the relevant information
        ie. When to board a train, change trains or leave a station
    """
    for u,v in zip(path,path[1:]):
        u_data = H.nodes(data=True)[u]
        v_data = H.nodes(data=True)[v]
        edge_data = H[u][v]

        # Starting information
        if edge_data['movement'] == 'Start':
            print('Start journey from {} at {}\n'.format(u_data['StopPointName'],
                                                  minutes_to_time(v_data['MinuteOfDay'] - edge_data['cost'])))

        # Changing onto a train from waiting at a platform
        elif previous_edge['movement'] == 'Start' or \
             (previous_edge['movement'] == 'Stay' and previous_edge['movement'] != edge_data['movement']):
            print('Board the {:>7} line train from {} at {}'.format(edge_data['movement'],
                                                             u_data['StopPointName'],
                                                             minutes_to_time(u_data['MinuteOfDay'])))

        # Changing off a train from travelling through any number of stops
        elif edge_data['movement'] != previous_edge['movement'] and edge_data['movement'] == 'Stay':
            print('Disembark the {:>3} line train at {} at {}'.format(previous_edge['movement'],
                                                               u_data['StopPointName'], 
                                                               minutes_to_time(u_data['MinuteOfDay'])))

        # Finishing information
        elif edge_data['movement'] == 'End':
            print('\nFinish journey at {} at {}'.format(u_data['StopPointName'],
                                                 minutes_to_time(u_data['MinuteOfDay'])))

        previous_edge = edge_data

def plan_journey(H, path_query):
    """
        Add Start and End nodes to the network temporarily based on `path_query`
        Calculate and print shortest path
        Remove Start and End nodes (along with any induced edges) to 'clean' network for next query
    """
    setup_shortest_path(path_query)
    path = nx.shortest_path(H, source='Start', target='End', weight='cost')
    print_path(path)
    H.remove_nodes_from(['Start', 'End'])

if __name__ == '__main__':
    
    # Location of NetworkX GPickle object
    file = "../../1_data/1_3_saved_analysis_objects/DeparturesGraph20171218.gpickle"
    
    H = nx.read_gpickle(file)
    
    query = example_path_query
    plan_journey(H, query)
    
    print('\n')
    query['To_StopPointName'] = 'Mile End'
    plan_journey(H, query)

#> Start journey from Bank at 09:00:00
#>
#> Board the     CEN line train from Bank at 09:01:00
#> Disembark the CEN line train at Oxford Circus at 09:09:00
#> Board the     VIC line train from Oxford Circus at 09:10:00
#>
#> Finish journey at Victoria at 09:14:00
#>
#> Start journey from Bank at 09:00:00
#>
#> Board the     CEN line train from Bank at 09:00:00
#>
#> Finish journey at Mile End at 09:07:00

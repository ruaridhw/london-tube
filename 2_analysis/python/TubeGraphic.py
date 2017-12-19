#' ## Tube Graphic

import networkx as nx
import psycopg2

conn = psycopg2.connect(host="localhost",database="londontubeprodr2", user="postgres", password="mysecretpassword")
cur = conn.cursor()

cur.execute("SELECT * FROM inbound_graph")
tablerows = cur.fetchall()

G = nx.MultiGraph()

for row in tablerows:
    if row[1] not in G:
        G.add_node(row[1], lon = row[3], lat = row[4])
    if row[2] not in G:
        G.add_node(row[2], lon = row[5], lat = row[6])
    G.add_edge(row[1], row[2], line = row[0])

cur.close()
conn.close()

print(nx.info(G))
# Name:
# Type: Graph
# Number of nodes: 269
# Number of edges: 310
# Average degree:   2.3048

from matplotlib import pyplot as plt
from networkx.drawing.nx_agraph import graphviz_layout

options = {
    'node_color': 'b',
    'node_size': 20,
    'width': 0.3,
    'alpha': 0.8,
    'with_labels': False,
}

pos = graphviz_layout(G, prog = 'circo')

plt.subplots(figsize=(10,10))
nx.draw_networkx_edges(G, pos = pos, **options)
plt.tight_layout()
plt.axis('off');

#edges = G.edges(data=True)
#edge_colours = [line_colours[data['line']] for u,v,data in edges]

#nx.draw(G, pos, edges=edges, edge_color=edge_colours, node_color = 'b', node_size = 2, width = 0.3, alpha = 0.8)

# Somewhere in the internet archives there are the official Tube RGB colours...
# https://web.archive.org/web/20080228103621/http://www.tfl.gov.uk/tfl/corporate/media/designstandards/assets/downloads/tfl/ColourStandardsIssue02.pdf
line_colours = {
    'VIC': (0, 160, 226),
    'PIC': (0, 25, 168),
    'WAC': (118, 208, 189),
    'NTN': (0, 0, 0),
    'HAM': (215, 153, 175),
    'BAK': (137, 78, 36),
    'CIR': (255, 206, 0),
    'DIS': (0, 114, 41),
    'CEN': (220, 36, 31),
    'JUB': (134, 143, 152),
    'MET': (117, 16, 86),
}
# Convert to [0,1] scale
line_colours = {line: tuple([x / 255.0 for x in rgb]) for line, rgb in line_colours.items()}

options = {
    'edges': G.edges(),
    'edge_color': [line_colours[data['line']] for u,v,data in G.edges(data=True)],
    'node_color': 'b',
    'node_size': 20,
    'width': 3,
    'alpha': 0.8,
    'with_labels': False,
}

pos = graphviz_layout(G, prog = 'neato')

plt.subplots(figsize=(20,20))
nx.draw_networkx_edges(G, pos = pos, **options)
plt.tight_layout()
plt.axis('off');


pos = {node: (data['lon'],data['lat']) for node,data in G.nodes(data=True)}

plt.subplots(figsize=(30,20))
nx.draw_networkx_edges(G, pos = pos, **options)
plt.tight_layout()
plt.axis('off');

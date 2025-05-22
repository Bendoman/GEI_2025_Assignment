 Ant Behavior Simluation

Name: Ben Corran

Student Number: C21430484

[Youtube Demonstration](https://youtu.be/PxpwKOKaJQU)

# Description of the project
This project consists of a fully interactable simulation of ant colonies. Up to four different ant bases can be placed by the user, ants will spawn, wander throughout the arena, find food and leave trails for other ants to follow. Food is brought back to the base in order to spawn new ants. If enemy ants have been detected, warrior ants will be spawned that kill ants originating from other bases. MultiMeshes were used in order to support upwards of 3 thousand ants existing and following their movement logic simultaneously while maintaining a consistent performance. 3 thousand ants can be supported when running the program without VR, around 2000 can be achieved when using a headset before performance degredation. 
All footage has been recorded with a Quest 2 running on a wired quest link, I am not sure how the performance will be if a quest 3 runs it natively. 

# Inspiration
https://github.com/user-attachments/assets/92a317a7-a8a3-4f40-83c8-029386e59a2c

# Recreation
![image](https://github.com/user-attachments/assets/7ac1efef-1761-455a-8d16-28c9fc6003d1)

# Usage
A floating control panel is used to control the simulation.
![image](https://github.com/user-attachments/assets/7bd372e9-2afa-4c17-8612-323b015da49c)

Bases and food sources will be placed wherever the user is standing 
![image](https://github.com/user-attachments/assets/70a51c9b-7890-441c-927d-6a987b98c4fc)

They can also be moved by grabbing the orb above them. These will disappear, and the controls will be disabled when the simulation is set to run. <br>
![image](https://github.com/user-attachments/assets/4d0b87bd-b5ca-40ff-aa89-007e7d9a0427)

Stopping the simulation resets all ant bases and food sources. 

Ants wander up to the edge of the arena searching for food. A world grid system is used so that they can scan to see obstacles and food sources. If a food source is close they will hone in on it and add a trail that the rest of the ants on their team will also follow if they are within range. If enemy ants are detected, ants will backtrack to the base and alert of their contact, queueing a warrior to spawn. Warriors chase down and kill enemy ants, they do not pick up food but do follow trails left by worker ants. 




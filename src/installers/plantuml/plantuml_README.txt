
PlantUML README
===============================================================================

http://plantuml.com/


PlantUML in a nutshell
----------------------------------

PlantUML is a component that allows to quickly write :

   Sequence diagram
   Usecase diagram
   Class diagram
   Activity diagram
   Component diagram
   State diagram
   Object diagram
   Deployment diagram
   Timing diagram


The following non-UML diagrams are also supported:

   Wireframe graphical interface
   Archimate diagram
   Specification and Description Language (SDL)
   Ditaa diagram
   Gantt diagram
   MindMap diagram
   Work Breakdown Structure diagram
   Mathematic with AsciiMath or JLaTeXMath notation
   Entity Relationship diagram


Diagrams are defined using a simple and intuitive language. (see PlantUML 
Language Reference Guide).  http://plantuml.com/en/guide

New users can read the quick start page.  There is also a F.A.Q. page. 

Images can be generated in PNG, in SVG, or in LaTeX format.  It is also 
possible to generate ASCII art diagrams (only for sequence diagrams).
 
PlantUML can be used within many other tools; there are various extensions or 
add-ons that incorporate PlantUML:

   Atom has a community maintained PlantUML syntax highlighter and viewer.
   Eclipse has a PlantUML plug-in.
   Google Docs has a "PlantUML Gizmo" add-on (works with the PlantUML server).
   LaTeX, using the Tikz package, has limited support for PlantUML.
   LibreOffice has a "Libo_PlantUML" extension to use PlantUML diagrams.
   Microsoft Word can use PlantUML diagrams via a Word Template Add-in. 
   Visual Studio Tools for Office has an add-in called "PlantUML Gizmo".
   Visual Studio Code has a PlantUML plug-in for Microsoft IDE users.


Common Commands
----------------------------------

See http://plantuml.com/commons for details.

   * Comments
   * Headers & Footers
   * Zooming
   * Titles
   * Captions
   * Diagram legends


Preprocessing
----------------------------------

Some minor preprocessing capabilities are included in PlantUML, and available 
for all diagrams.

These functionalities are very similar to the C language preprocessor, except 
that the special character # has been changed to the exclamation mark !.

See http://plantuml.com/preprocessing for details.

   * Variable definitions
   * Conditions 
   * Void function
   * Return function
   * Default arguments
   * Include files & URLs
   * Including subparts
   * Built-in functions
   * Logging
   * Memory dumps
   * Assertions
   * Building custom libraries
   * Search paths
   * Argument concatenation
   * Dynamic function invocation

 
Huge Diagrams
----------------------------------

PlantUML limits image width and height to 4096.  There is a environment 
variable that you can set to override this limit: PLANTUML_LIMIT_SIZE.  You 
have to define this variable before launching PlantUML, with something like:

   $ export PLANTUML_LIMIT_SIZE=8192

Another way is an option in the command line:

   $ java -DPLANTUML_LIMIT_SIZE=8192 -jar /path/to/plantuml.jar ...
   
Note that if you generate very big diagrams, (for example, something like 
20,000 x 10,000 pixels), you can have some memory issues.  The solution is 
to add this parameter to the Java VM: -Xmx1024m.


===============================================================================


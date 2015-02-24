# Copyright (c) 2015 , Franklin Sobrinho.                 
                                                                       
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without 
# limitation the rights to use, copy, modify, merge, publish,   
# distribute, sublicense, and/or sell copies of the Software, and to    
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions:                                             
                                                                       
# The above copyright notice and this permission notice shall be        
# included in all copies or substantial portions of the Software.       
                                                                       
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

tool
extends EditorPlugin

var toolbar_menu
var popup_menu

#MeshData class, it's function is generate and store the mesh arrays

class MeshData:
	var verts = []
	var uv = []
	var faces = []
	
	func find_last(array, element):
		var last = 0
		for i in range(array.size()):
			if element == array[i]:
				last = i
		return last
	
	func add_tri(coords_zero, coords_one, coords_two, reverse = false):
		var verts = []
		verts.append(coords_zero)
		verts.append(coords_one)
		verts.append(coords_two)
		
		var uv = []
		uv.append(Vector2(0,0))
		uv.append(Vector2(0,1))
		uv.append(Vector2(1,1))
	
		self.verts += verts
		self.uv += uv
		
		var faces = []
		var face1 = [find_last(self.verts, coords_one), find_last(self.verts, coords_two), find_last(self.verts, coords_zero)]
		faces.append(face1)
		
		if reverse:
			faces[0].invert()
		
		self.faces += faces
	
	func add_quad(four_vertex_array):
		var vertex = four_vertex_array
		var verts = []
		verts.append(vertex[0])
		verts.append(vertex[1])
		verts.append(vertex[2])
		verts.append(vertex[3])
		
		var uv = []
		uv.append(Vector2(1,1))
		uv.append(Vector2(0,0))
		uv.append(Vector2(1,0))
		uv.append(Vector2(0,1))
			
		self.verts += verts
		self.uv += uv
		
		var faces = []
		var face1 = [find_last(self.verts, vertex[2]),\
		             find_last(self.verts, vertex[0]),\
		             find_last(self.verts, vertex[1])]
		var face2 = [find_last(self.verts, vertex[1]),\
		             find_last(self.verts, vertex[0]),\
		             find_last(self.verts, vertex[3])]
		faces.append(face1)
		faces.append(face2)
		
		self.faces += faces

func _init():
	print("PLUGIN INIT")

func _enter_tree():
	toolbar_menu = MenuButton.new()
	toolbar_menu.set_text('Add Mesh')
	popup_menu = toolbar_menu.get_popup()
	
	update_menu()
	
	add_custom_control(CONTAINER_SPATIAL_EDITOR_MENU, toolbar_menu)
	popup_menu.connect('item_pressed', self, '_popup_signal')

func update_menu():
	popup_menu.add_item('Add Cube')
	popup_menu.add_item('Add Plane')
	popup_menu.add_item('Add Cylinder')
	
	#popup_menu.add_separator()
	#popup_menu.add_item('Immediate Geometry')
	#popup_menu.add_item('Add Heigthmap')
	#popup_menu.add_separator()
	
func _popup_signal(id):
	var command = popup_menu.get_item_text(popup_menu.get_item_index(id))
	
	#if command == 'Settings':
	#	pass
	
	if command == 'Add Plane':
		var quad = build_plane(Vector3(2,0,0), Vector3(0,0,2), Vector3(-1,0,-1))
		surface_tool(quad)
	
	elif command == 'Add Cube':
		var box = build_box()
		surface_tool(box)
	
	elif command == 'Add Cylinder':
		var cylinder = build_cylinder(16, 2)
		surface_tool(cylinder)
	
	#elif command == 'Add Heigthmap':
	#	var heigthmap = build_heigthmap()
	#	surface_tool(heigthmap)
	
	#elif command == 'Immediate Geometry':
	#	#Here you can add any function here to use Immediate Geometry API
	#	var box = build_box()
	#	immediate_geometry(box)
	

#Procedual algorithms

func build_plane(width_dir, length_dir, offset = Vector3(0,0,0)):
	var verts = []
	verts.append(Vector3(0,0,0) + offset)
	verts.append(Vector3(0,0,0) + offset + length_dir)
	verts.append(Vector3(0,0,0) + offset + length_dir + width_dir)
	verts.append(Vector3(0,0,0) + offset + width_dir)
	
	var faces = []
	faces.append([2,1,0])
	faces.append([3,2,0])
	
	var uv = []
	uv.append(Vector2(0,0))
	uv.append(Vector2(0,1))
	uv.append(Vector2(1,1))
	uv.append(Vector2(1,0))
	
	var mesh = MeshData.new()
	mesh.add_quad([verts[0], verts[2], verts[1], verts[3]])
	
	return mesh
	
func build_box():
	var offset = Vector3(-1,-1,-1)
	
	var foward_dir = Vector3(2,0,0)
	var rigth_dir = Vector3(0,0,2)
	var up_dir = Vector3(0,2,0)
	
	var faces = []
	faces.append(build_plane(foward_dir, rigth_dir, offset))
	faces.append(build_plane(rigth_dir, up_dir, offset))
	faces.append(build_plane(up_dir, foward_dir, offset))
	faces.append(build_plane(-rigth_dir, -foward_dir, -offset))
	faces.append(build_plane(-up_dir, -rigth_dir, -offset))
	faces.append(build_plane(-foward_dir, -up_dir, -offset))
	
	var mesh = MeshData.new()
	for face in range(0, faces.size()):
		var temp = faces[face].verts
		mesh.add_quad([temp[1], temp[0], temp[2], temp[3]])
		
	return mesh

func build_cylinder(segments, heigth, caps = true):
	var radians_circle = PI * 2
	
	var h = Vector3(0, heigth/2, 0)
	
	var circle_verts = []
	
	for i in range(segments):
		var angle = radians_circle * i/segments
		var x = cos(angle)
		var z = sin(angle)
		
		circle_verts.append(Vector3(x, 0, z))
	
	var mesh = MeshData.new()
	
	for i in range(segments - 1):
		var index0 = 0 + i
		var index1 = 1 + i
		
		mesh.add_quad([circle_verts[index0] - h,\
		              circle_verts[index1] + h,\
		              circle_verts[index0] + h,\
		              circle_verts[index1] - h])
		
	mesh.add_quad([circle_verts[segments - 1] - h,\
	              circle_verts[0] + h,\
	              circle_verts[segments - 1] + h,\
	              circle_verts[0] - h])
	
	if caps:
		for i in range(segments - 1):
			var index0 = 0 + i 
			var index1 = 1 + i
		
			mesh.add_tri(circle_verts[index0] + h, circle_verts[index1] + h, h)
			mesh.add_tri(circle_verts[index0] - h, circle_verts[index1] - h, -h, true)
	
		mesh.add_tri(circle_verts[segments - 1] + h, circle_verts[0] + h, h)
		mesh.add_tri(circle_verts[segments - 1] - h, circle_verts[0] - h, -h, true)
	return mesh

#This is just a experiment, and for now is just a bumpy surface
#WARNING: There is a perfomace issue related to it

func build_heigthmap(size = 50, res = 32):
	var origin = Vector3(-25,0,-25)
	var res_size = float(size)/res
	
	var verts = []
	
	for i in range(res + 1):
		verts.append([])
		for j in range(res + 1):
			verts[i] += [Vector3(i * res_size, randf(5), j * res_size)]
	
	var mesh = MeshData.new()
	
	for i in range(res):
		for j in range(res):
			mesh.add_quad([verts[i+1][j] + origin,\
			              verts[i][j+1] + origin,\
			              verts[i][j] + origin,\
			              verts[i+1][j+1] + origin])
			
	return mesh

#Function for the next way of adding geometry,
#it will use function Mesh.add_surface(), but it 
#still far to be functional

#func add_mesh(mesh):
#	var mesh_instance = MeshInstance.new()
#	
#	var root = get_tree().get_nodes_in_group('_viewports')[1].get_child(0)
#	
#	if root != null:
#		root.add_child(mesh_instance)
#		mesh_instance.set_owner(root)

#Immediate Geometry, still experimental

func immediate_geometry(mesh):
	var immediate_geo = ImmediateGeometry.new()
	#Here it create a new texture to nescessary to add geometry
	var texture = ImageTexture.new()
	texture.create(256, 256, 0)
	
	immediate_geo.begin(4, texture)
	
	for face in mesh.faces:
		for idx in face:
			immediate_geo.set_normal(mesh.verts[idx].normalized())
			immediate_geo.add_vertex(mesh.verts[idx])
			print(mesh.verts[idx])
	
	var root = get_tree().get_nodes_in_group('_viewports')[1].get_child(0)
	
	immediate_geo.end()
	
	if root == null:
		pass
	else:
		if root.get_type() != 'Spatial':
			for node in root.get_children():
				if node.get_type() == 'Spatial':
					node.add_child(immediate_geo)
					immediate_geo.set_owner(root)
					break
		else:
			root.add_child(immediate_geo)
			immediate_geo.set_owner(root)

#Main function to add geometry, all the plugin engine is based on it

func surface_tool(mesh):
	var mesh_instance = MeshInstance.new()
	var _mesh = Mesh.new()
	var surf = SurfaceTool.new()
	var meshdata_tool = MeshDataTool.new()

	surf.begin(4)
	
	for face in mesh.faces:
		surf.add_smooth_group(false)
		for idx in face:
			surf.add_uv(mesh.uv[idx])
			surf.add_vertex(mesh.verts[idx])
		
	surf.generate_normals()
	_mesh = surf.commit()
	
	mesh = null
	
	_mesh.center_geometry()
	mesh_instance.set_mesh(_mesh)
	
	var root = get_tree().get_nodes_in_group('_viewports')[1].get_child(0)
	
	if root == null:
		pass
	else:
		if root.get_type() != 'Spatial':
			for node in root.get_children():
				if node.get_type() == 'Spatial':
					node.add_child(mesh_instance)
					mesh_instance.set_owner(root)
					break
		else:
			root.add_child(mesh_instance)
			mesh_instance.set_owner(root)
		
func _exit_tree():
	popup_menu.free()
	popup_menu = null
	toolbar_menu.free()
	toolbar_menu = null


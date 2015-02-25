# Copyright (c) 2015 Franklin Sobrinho.                 
                                                                       
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

var StaticMeshBuilder
var SettingsWindow

var experimental_builder = false

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
	
	StaticMeshBuilder = preload("StaticMeshBuilder.gd").new()
	SettingsWindow = preload("SettingsWindow.xml").instance()
	
	add_custom_control(CONTAINER_SPATIAL_EDITOR_MENU, toolbar_menu)
	popup_menu.connect('item_pressed', self, '_popup_signal')

func update_menu():
	popup_menu.add_item('Add Cube')
	popup_menu.add_item('Add Plane')
	popup_menu.add_item('Add Cylinder')
	
	popup_menu.add_separator()
	#popup_menu.add_item('Immediate Geometry')
	popup_menu.add_item('Add Heigthmap')
	popup_menu.add_separator()
	popup_menu.add_item('Settings')
	
func _popup_signal(id):
	var command = popup_menu.get_item_text(popup_menu.get_item_index(id))
	
	if command == 'Add Plane':
		if experimental_builder:
			StaticMeshBuilder.begin(4)
			StaticMeshBuilder.add_quad(exp_build_plane(Vector3(2,0,0), Vector3(0,0,2), Vector3(-1,0,-1)), true)
			StaticMeshBuilder.generate_normals()
		
			exp_add_mesh(StaticMeshBuilder.commit())
			StaticMeshBuilder.clear()
		
		else:
			var quad = build_plane(Vector3(2,0,0), Vector3(0,0,2), Vector3(-1,0,-1))
			surface_tool(quad)
		
	elif command == 'Add Cube':
		if experimental_builder:
			var box = exp_build_box(Vector3(-1,-1,-1))
			exp_add_mesh(box)
		else:
			var box = build_box()
			surface_tool(box)
		
	elif command == 'Add Cylinder':
		if experimental_builder:
			var cylinder = exp_build_cylinder(2, 16)
			exp_add_mesh(cylinder)
		else:
			var cylinder = build_cylinder(16, 2)
			surface_tool(cylinder)
	
	elif command == 'Add Heigthmap':
		if experimental_builder:
			print('--')
			var heigthmap = exp_build_heigthmap()
			exp_add_mesh(heigthmap)
		else:
			var heigthmap = build_heigthmap()
			surface_tool(heigthmap)
	
	#elif command == 'Immediate Geometry':
	#	#Here you can add any function here to use Immediate Geometry API
	#	var box = build_box()
	#	immediate_geometry(box)
	
	elif command == 'Settings':
		if SettingsWindow.is_hidden():
			SettingsWindow.show()
		elif SettingsWindow.get_parent() == null:
			add_child(SettingsWindow)
		elif has_node(get_path_to(SettingsWindow)):
			remove_child(SettingsWindow)
			add_child(SettingsWindow)
		
		var window_size = get_tree().get_root().get_rect()
		
		SettingsWindow.popup_centered()
		
		var check_button = SettingsWindow.get_node('ExperimentalBuilder')
		check_button.set_pressed(experimental_builder)
		var close_button = SettingsWindow.get_node('close_button')
		if not check_button.is_connected('toggled', self, '_experimental_builder'):
			check_button.connect('toggled', self, '_experimental_builder')
		if not close_button.is_connected('pressed', self, '_ok_button'):
			close_button.connect('pressed', self, '_ok_button')
		
#Settings
func _experimental_builder(pressed):
	if not pressed:
		experimental_builder = false
	else:
		experimental_builder = true

func _ok_button():
	SettingsWindow.hide()
	
#Procedual algorithms

func exp_build_plane_verts(width_dir, length_dir, offset = Vector3(0,0,0)):
	var verts = []
	verts.append(Vector3(0,0,0) + offset)
	verts.append(Vector3(0,0,0) + offset + length_dir + width_dir)
	verts.append(Vector3(0,0,0) + offset + length_dir)
	verts.append(Vector3(0,0,0) + offset + width_dir)
	
	return verts

func exp_build_box(offset = Vector3(0,0,0)):
	var foward_dir = Vector3(2,0,0)
	var rigth_dir = Vector3(0,0,2)
	var up_dir = Vector3(0,2,0)
	
	StaticMeshBuilder.begin(4)
	
	StaticMeshBuilder.add_quad(exp_build_plane_verts(foward_dir, rigth_dir, offset))
	StaticMeshBuilder.add_quad(exp_build_plane_verts(rigth_dir, up_dir, offset))
	StaticMeshBuilder.add_quad(exp_build_plane_verts(up_dir, foward_dir, offset))
	StaticMeshBuilder.add_quad(exp_build_plane_verts(-rigth_dir, -foward_dir, -offset))
	StaticMeshBuilder.add_quad(exp_build_plane_verts(-up_dir, -rigth_dir, -offset))
	StaticMeshBuilder.add_quad(exp_build_plane_verts(-foward_dir, -up_dir, -offset))
	
	StaticMeshBuilder.generate_normals()
	var mesh = StaticMeshBuilder.commit()
	StaticMeshBuilder.clear()
	return mesh

func exp_build_circle_verts(pos, segments):
	var radians_circle = PI * 2
	
	var circle_verts = []
	
	for i in range(segments):
		var angle = radians_circle * i/segments
		var x = cos(angle)
		var z = sin(angle)
		
		circle_verts.append(Vector3(x, 0, z) + pos)
	
	return circle_verts

func exp_build_cylinder(heigth, segments, caps = true):
	var circle = exp_build_circle_verts(Vector3(0,float(heigth)/2,0), 16)
	
	StaticMeshBuilder.begin(4)
	
	var min_pos = Vector3(0,heigth * -1,0)
	
	if caps:
		for idx in range(segments - 1):
			StaticMeshBuilder.add_tri([Vector3(0,float(heigth)/2,0), circle[idx + 1], circle[idx]])
			StaticMeshBuilder.add_tri([min_pos * 0.5, circle[idx + 1] + min_pos, circle[idx] + min_pos], true)
		StaticMeshBuilder.add_tri([Vector3(0,float(heigth)/2,0), circle[0], circle[segments - 1]])
		StaticMeshBuilder.add_tri([min_pos * 0.5, circle[0] + min_pos, circle[segments - 1] + min_pos], true)
	
	for idx in range(segments - 1):
		StaticMeshBuilder.add_quad([circle[idx] + min_pos, circle[idx + 1], circle[idx], circle[idx + 1] + min_pos], true)
	StaticMeshBuilder.add_quad([circle[0] + min_pos, circle[segments - 1], circle[0], circle[segments - 1] + min_pos])
	
	StaticMeshBuilder.generate_normals()
	var mesh = StaticMeshBuilder.commit()
	StaticMeshBuilder.clear()
	
	return mesh

func exp_build_heigthmap(size = 50, res = 32):
	var origin = Vector3(-25,0,-25)
	var res_size = float(size)/res
	
	var verts = []
	
	for i in range(res + 1):
		verts.append([])
		for j in range(res + 1):
			verts[i] += [Vector3(i * res_size, randf(5), j * res_size)]
	
	StaticMeshBuilder.begin(4)
	
	for i in range(res):
		for j in range(res):
			StaticMeshBuilder.add_quad([verts[i+1][j] + origin,\
			                            verts[i][j+1] + origin,\
			                            verts[i][j] + origin,\
			                            verts[i+1][j+1] + origin], true)
	
	StaticMeshBuilder.generate_normals()
	var mesh = StaticMeshBuilder.commit()
	StaticMeshBuilder.clear()
	
	return mesh
	
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

func exp_add_mesh(mesh):
	var mesh_instance = MeshInstance.new()
	mesh_instance.set_mesh(mesh)
	
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
	StaticMeshBuilder = null
	popup_menu.free()
	popup_menu = null
	toolbar_menu.free()
	toolbar_menu = null


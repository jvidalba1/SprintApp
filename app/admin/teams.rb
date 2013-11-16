#encoding: utf-8
ActiveAdmin.register Team, :sort_order => "name_asc" do
  
  controller.authorize_resource
  
  menu :label => "Equipo", :parent => "Administración", :if => proc { can?(:index, Team) }
    
  filter :name, :label => "Nombre"
  filter :description, :label => "Descripción"
  filter :created_at, :label => "Creado"
  filter :updated_at, :label => "Actualizado"
  
  index do
    selectable_column
    column("Nombre", :sortable => :name) { |team| link_to team.name, team }
    column("Creado", :sortable => :created_at) { |team| team.created_at.humanize }
    column("Actualizado", :sortable => :updated_at) { |team| team.updated_at.humanize }
    default_actions
  end
  
  show :title => :name do
    panel "Detalles de equipo" do
      attributes_table_for resource do
        row("Nombre") { resource.name}
        row("Descripción") {resource.description}
        row "Miembros" do
          raw(resource.admin_users.collect { |user| link_to user.full_name, user }.join(", "))
        end
      end
    end
  end
  
  form :partial => "form"
  
end

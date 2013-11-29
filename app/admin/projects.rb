#encoding: utf-8
ActiveAdmin.register Project, :sort_order => "number_asc" do
    
  menu :label => "Proyectos", :priority => 4
  
  # for use with cancan
  controller.authorize_resource find_by: :url
  controller.resources_configuration[:self][:finder] = :find_by_url!
    
  before_filter :set_project, only: [:whiteboard, :edit_whiteboard, :save_whiteboard, :switch, :archive, :unarchive, :roadmap]
    
  filter :number, :label => "Número"
  filter :client, :label => "Cliente", :collection => proc { Client.all }
  filter :product_owner, :collection => proc { AdminUser.admin }
  filter :name, :label => "Nombre"
  filter :start_date, :label => "Fecha de inicio"
  filter :end_date, :label => "Fecha fin"
  filter :description, :label => "Descripción"
  filter :created_at, :label => "Creado"
  filter :updated_at, :label => "Actualizado"
  
  scope :all
  scope :active, default: true
  scope :closed
  
  action_item :only => [:show] do
    if controller.current_ability.can?(:archive, Project)
      if resource.completed?
        link_to "Activar", unarchive_project_path(resource), confirm: "¿Esta seguro que quiere activar este proyecto?"
      else
        link_to "Desactivar", archive_project_path(resource), confirm: "¿Esta seguro que quiere archivar este proyecto? \nAún puedes ver todos los datos del proyecto, o desarchivar el proyecto luego."
      end
    end
  end
  
  controller do
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end
  
  batch_action :archive, { if: proc { can? :archive, Project }, confirm: '¿Esta seguro que quiere archivar estos proyecto?' } do |selected_ids|
    Project.find(selected_ids).each { |u| u.archive! }
    redirect_to collection_path, notice: "#{selected_ids.count} proyectos archivados exitosamente."
  end
  
  batch_action :unarchive, { if: proc{ can? :unarchive, Project }, confirm: '¿Esta seguro que quiere desarchivar estos proyectos?' } do |selected_ids|
    Project.find(selected_ids).each { |u| u.unarchive! }
    redirect_to collection_path, notice: "#{selected_ids.count} proyectos desarchivados exitosamente."
  end
  
  batch_action :destroy, { if: proc{ can? :destroy, Project }, priority: 100, confirm: I18n.t('active_admin.batch_actions.delete_confirmation', plural_model: "projects") } do |selected_ids|
    Project.destroy_all id: selected_ids
    redirect_to collection_path, :notice => I18n.t("active_admin.batch_actions.succesfully_destroyed", count: selected_ids.count, model: "project", plural_model: "projects")
  end
  
  index do |t|
    selectable_column
    column("Número", sortable: :number) { |project| link_to project.number, project if project.number.present? }
    column("Cliente", :sortable => :client_id) { |project| link_to truncate(project.client_name, length: 35), client_path(project.client), title: project.client_name }
    column("Nombre", sortable: :name) { |project| link_to truncate(project.name, length: 35), project_path(project), title: project.name }
    column :product_owner, :sortable => :product_owner_id
    column "" do |project|
      restricted_default_actions_for_resource(project) + link_to("Tickets", project_tickets_path(project))
    end
  end
  
  form :partial => 'form'
  
  show :title => proc { truncate resource.display_name, length: 50 } do
   panel "Detalle de proyecto" do
      attributes_table_for resource do
        row("Número") { resource.number }
        row("Nombre") { resource.name}
        row("Cliente") { link_to resource.client.display_name, resource.client }
        row("Precio por hora") { number_to_currency resource.hourly_rate } unless current_admin_user.employee?
        row "Fecha de inicio" do
          resource.start_date.humanize
        end
        row "Fecha fin" do
          resource.safe_end_date
        end
        row "Descripción" do
          resource.description.html_safe
        end
      end
    end
  end
  
  sidebar "Interno / Contabilidad", :only => [:show] do
    attributes_table_for resource do
      row "Propietario" do
        link_to resource.product_owner.full_name, admin_user_path(resource.product_owner)
      end
      row "Estado" do
        status_tag resource.completed? ? 'Completado' : 'En progreso', resource.completed? ? :green : :warn
      end
    end
  end

  sidebar :members, :only => [:show]

  sidebar "Roadmap de proyecto", :only => [:roadmap] do
    para "Un Roadmap del proyecto describe el progreso de todo el proyecto, y el progreso para todos los hitos activos para que puedas ver facilmente la vida del proyecto."
    para strong("Progreso ticket") + text_node("es un indicador de estado para mostrar los tickets que están atrasados.")
    para strong("Progreso de presupuesto") + text_node("muestra rapidamente si el proyecto está por encima o por debajo del presupuesto")
    para strong("Facturable vs No-Facturable") + text_node("muesta la relación de Facturable a No-Facturable tiempo completo")
  end
  
  sidebar "Información del proyecto", only: :roadmap do
    @project = Project.find_by_url! params[:id]
    @tickets = @project.tickets
    @milestones = @project.milestones
    @num_assignees = @tickets.select(:assignee_id).uniq { |t| t.assignee_id }.count
    @total_hours = @tickets.sum :estimated_time
    render partial: "project_information_sidebar", locals: { tickets: @tickets, milestones: @milestones, num_assignees: @num_assignees, total_hours: @total_hours }
  end
  
  member_action :roadmap do
    redirect_to projects_path, :alert => "No se puede recuperar proyecto deseado." if @project.nil?
  end
  
  member_action :whiteboard do
    redirect_to projects_path, alert: "No se puede recuperar proyecto deseado.", status: :not_found if @project.nil?
  end
  
  member_action :edit_whiteboard do
    redirect_to projects_path, alert: "No se puede recuperar proyecto deseado.", status: :not_found if @project.nil?
  end
  
  member_action :save_whiteboard, method: :put do
    redirect_to projects_path, alert: "No se puede recuperar proyecto deseado.", status: :not_found if @project.nil?

    if @project.update_attributes(params[:project])
      redirect_to whiteboard_project_path(@project), notice: "Pizarra de proyecto actualizada."
    else
      redirect_to whiteboard_project_path(@project), alert: "Error para actualizar pizarra del proyecto."
    end
  end
  
  member_action :archive do
    unless @project.nil?
      @project.archive!
      redirect_to projects_path, :notice => "Proyecto archivado."
    else
      redirect_to projects_path, :alert => "No se puede recuperar proyecto deseado."
    end
  end
  
  member_action :unarchive do
    unless @project.nil?
      @project.unarchive!
      redirect_to projects_path, :notice => "Proyecto desarchivado."
    else
      redirect_to projects_path, :alert => "No se puede recuperar proyecto deseado."
    end
  end
  
  collection_action :switch, method: :post do
    redirect_to project_tickets_path(@project)
  end
  
  controller do
    
    def set_project
      @project = Project.find_by_url! params[:id]
    end
     
  end
  
end
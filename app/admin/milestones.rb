#encoding: utf-8
ActiveAdmin.register Milestone, :sort_order => "start_date_asc" do
  
  # for use with cancan
  controller.authorize_resource
  controller.resources_configuration[:self][:finder] = :find_by_url!
  
  belongs_to :project, finder: :find_by_url!
  
  filter :name
  filter :start_date
  filter :end_date
  filter :description
  filter :created_at
  filter :updated_at
  
  scope :all
  scope :active, :default => true
  scope :closed
  
  action_item :only => :show do
    link_to "Roadmap", roadmap_project_milestone_path(resource)
  end
  
  batch_action :destroy, { if: proc{ can? :destroy, Milestone }, priority: 100, confirm: I18n.t('active_admin.batch_actions.delete_confirmation', plural_model: "milestones") } do |selected_ids|
    Milestone.destroy_all id: selected_ids
    redirect_to collection_path, :notice => I18n.t("active_admin.batch_actions.succesfully_destroyed", count: selected_ids.count, model: "milestone", plural_model: "milestones")
  end
  
  index do |t|
    selectable_column
    column(:name, sortable: :name) { |m| link_to m.name, [m.project, m] }
    column :start_date, :sortable => :start_date do |milestone|
      milestone.start_date.humanize
    end
    column :end_date, :sortable => :end_date do |milestone|
      milestone.safe_end_date
    end
    column "Completado" do |milestone|
      milestone_progress_indicator(milestone, false)
    end
    column "Presupuesto" do |milestone|
      milestone_budget_progress_indicator(milestone, false)
    end
    column "" do |milestone|
      actions = restricted_default_actions_for_resource(milestone)
      if can?(:complete, milestone)
        if milestone.completed?
          actions += link_to( "Revive", revive_project_milestone_path(milestone.project, milestone), confirm: "Are you sure you want to revive this milestone?" )
        else
          actions += link_to( "Complete", complete_project_milestone_path(milestone.project, milestone), confirm: "Are you sure you want to complete this milestone?" )
        end
      end
      actions
    end
  end
  
  form :html => { :class => "filter_form consolidated_form" } do |f|
    f.inputs "Hito", :class => "inputs consolidated" do
      f.input :name
      f.input :start_date, :as => :datepicker, :wrapper_html => { :class => "filter_form_field filter_date_range field-row" }
      f.input :end_date, :as => :datepicker, :wrapper_html => { :class => "filter_form_field filter_date_range field-row" }
      f.input :description, :input_html => { class: :ckeditor }, :wrapper_html => { :class => "cleared" }
    end
    f.buttons
  end
  
  show :title => :name do
    panel "Hito" do
      attributes_table_for resource do
        row :name
        row :start_date
        row :end_date
        row :completed
        row :description do 
          resource.description.html_safe rescue nil
        end
      end
    end
  end
  
  sidebar "Hito - Roadmap", :only => [:roadmap] do
    para "Un Roadmap para un hito muestra los avances para un logro, esta determinado por los tickets asignados a este hito"
    para strong("Progreso tickets") + text_node("es un indicador de estado ilustrando el progreso completado de los tickets. Entre más verde significa que está por delante de lo previsto y el rojo significa que está por detrás.")
    para strong("Progreso presupuesto") + text_node("muestra rapidamente si el hito esta por debajo o por encima del presupuesto.")
    para strong("Facturable vs No-facturable") + text_node("muestra la relación entre facturable a no-facturable - tiempo empleado")
  end
  
  member_action :roadmap do
    @milestone = Milestone.find_by_url!(params[:id], :include => [:project, :tickets]) rescue nil
    redirect_to(project_milestones_path(params[:project_id]), :alert => "No se pudo localizar el hito deseado") if @milestone.nil?
  end
  
  member_action :complete do
    @milestone = Milestone.find_by_url!(params[:id]) rescue nil
    unless @milestone.nil? 
      @milestone.completed = true
      @milestone.save
      redirect_to project_milestones_path(@milestone.project), :notice => "Hito completado exitosamente."
    else
      redirect_to project_milestones_path(params[:project_id]), :alert => "No se pudo localizar el hito deseado."
    end
  end
  
  member_action :revive do
    @milestone = Milestone.find_by_url!(params[:id]) rescue nil
    unless @milestone.nil?
      @milestone.completed = false
      @milestone.save
      redirect_to project_milestones_path(@milestone.project), :notice => "Hito recuperado exitosamente."
    else
      redirect_to project_milestones_path(params[:project_id]), :alert => "No se pudo localizar el hito deseado."
    end
  end
  
  controller do
    def end_of_association_chain
      super.except(:order)
    end
  end
  
end

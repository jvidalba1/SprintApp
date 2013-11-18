#encoding: utf-8
ActiveAdmin.register_page "CompanyRoadmap" do
  
  menu label: "Roadmap general", parent: "Reportes", if: proc { can? :index, :company_roadmap }
  
  controller.authorize_resource class: false
  
  sidebar "Ayuda" do
    para "En este reporte se muestra el progreso (salud) de todos los proyectos abiertos"
    para "Use esta información para determinar rapidamente cómo se encuentran los proyectos actuales"
  end
  
  controller do
    
    def index
      @page_title = 'Roadmap general'
      @projects = Project.active
      render layout: 'active_admin'
    end
    
  end
  
end
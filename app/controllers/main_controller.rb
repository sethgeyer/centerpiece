class MainController < ApplicationController
use Rack::Session::Cookie, secret: SecureRandom.hex 

###



######### SESSION SECURITY
OPEN_PAGES = ["/", "/login", "/logout", "/about_us"]
before_filter do
  if !OPEN_PAGES.include?(request.path_info) && session["found_florist_id"] == nil && session["found_user_id"] == nil
    render(:login, layout:false) and return
  elsif !OPEN_PAGES.include?(request.path_info) && (Employee.where(id: session["found_user_id"]).first.status == "Inactive" || Florist.where(id: session["found_florist_id"]).first.status == "Inactive")
     render(:login, layout:false) and return
  end 
end


######### PAGE_VIEW_PERMISSIONS
ADMIN_RIGHTS = ["None", "All Admin Rights", "Product Edit Only"]
EMPLOYEES_VIEW_MUST_HAVE = ["All Admin Rights"]
PRODUCT_UPDATE_MUST_HAVE = ["All Admin Rights", "Product Edit Only"]


######### WEBPAGE

def webpage
render(:webpage, layout:false) and return
end







######### LOGIN
  def login
    render(:login, layout:false) and return    
  end


  def logged_in
    found_florist = Florist.where(status: "Active").where(company_id: params["company_id"]).first    
    if found_florist != nil
      found_user = Employee.where(status: "Active").where(florist_id: found_florist.id).where(username: params["username"]).first
      if found_user && found_user.authenticate(params["password"])
        session["found_user_id"] = found_user.id
        session["found_florist_id"] = found_florist.id
        redirect_to home_path and return
      else
      end
    end
    render(:login, layout:false) and return
  end
  
 
 
 ############ ABOUT US
 def about_us
 render(:about_us, layout:false) and return
 end 
  
  

######### DISPLAY HOMEPAGE
  def home
      
      if Employee.where(id: session["found_user_id"]).first.status == "Inactive" || Florist.where(id: session["found_florist_id"]).first.status == "Inactive"
        redirect_to "/login" and return
      else
      end
      
      
      if Employee.where(id: session["found_user_id"]).first.view_pref == "all" ||
      Employee.where(florist_id: session["found_florist_id"]).where(username: Employee.where(id: session["found_user_id"]).first.view_pref).first  == nil
      @events = Event.where(florist_id: session["found_florist_id"]).where("event_status not like 'Lost'").where("event_status not like 'Completed'").order("date_of_event").paginate(:page => params[:page], :per_page => 100)
      else
      view_pref = Employee.where(id: session["found_user_id"]).first.view_pref
      employee_id = Employee.where(florist_id: session["found_florist_id"]).where(username: view_pref).first.id
      @events = Event.where(florist_id: session["found_florist_id"]).where(employee_id: employee_id).where("event_status not like 'Lost'").where("event_status not like 'Completed'").order("date_of_event").paginate(:page => params[:page], :per_page => 100)
      end
      @view_prefs = ["all"] + Employee.where(florist_id: session["found_florist_id"]).where(status: "Active").uniq.pluck(:username)
      render(:homepage) and return
  end
  

######### SEARCH OR LOGOUT BUTTONS ON HOMEPAGE
  def homepage
    if params["search"] #if they push the search button
      if params["search_field"] != ""
        customer = params["search_field"]
      else
        customer = "add_new_customer"
      end
      redirect_to "/search/#{customer}" and return
    elsif params["admin_access"]
      redirect_to "/florists" and return
    elsif params["update_view"]
      emp_update = Employee.where(id: session["found_user_id"]).first
      emp_update.view_pref = params["view"]
      emp_update.save!
      redirect_to home_path and return
   # else 
   #   redirect_to logout_path and return
    end
  end

  def logout
    session.clear
    render(:login, layout:false) and return
  end  
  
  
######### SEARCH RESULTS  
  def search_results
    @customers = Customer.where(florist_id: session["found_florist_id"]).where("name ilike ?","%#{params["customer"]}%") 
    render(:search_results) and return
  end  

######### NEW CUSTOMER

###GET Request from search_results.erb
  def cust_new   
    @new_customer =Customer.new
    render(:cust_new) and return  
  end

###POST Request from cust_new.erb 
  def create_new_customer   
    @new_customer = Customer.new
    @new_customer.name = params["new_contact_name"]
    @new_customer.company_name = params["company_name"]
    @new_customer.phone1 = params["phone1"]
    @new_customer.phone2 = params["phone2"]
    @new_customer.email = params["contact_email"]
    @new_customer.groom_name = params["groom_name"]
    @new_customer.groom_phone = params["groom_phone"]
    @new_customer.groom_email = params["groom_email"]
    @new_customer.address = params["address"]
    @new_customer.city = params["city"]
    @new_customer.state = params["state"]
    @new_customer.zip = params["zip"]
    @new_customer.notes = params["notes"]
    @new_customer.florist_id = session["found_florist_id"]
    if @new_customer.save
      redirect_to "/cust_edit/#{@new_customer.id}" and return
    else
      render(:cust_new) and return
    end
  end

######### EDIT CUSTOMER

###GET Handler from cust_new.erb, search_results.erb, or homepage.erb
  def edit_customer          
      cust_id = params["customer_id"]
      @customer = Customer.where(florist_id: session["found_florist_id"]).where(id: cust_id).first
      render(:cust_edit) and return
  end
  
###POST Handler from cust_edit.erb  
  def cust_edit             
    cust_id = params["customer_id"]
    if params["save"]
      @customer = Customer.where(id: cust_id).first  #NEEDS TO BE TIED TO LOGIN INFO
      @customer.name = params["contact_name"]
      @customer.company_name = params["company_name"]
      @customer.phone1 = params["phone1"]
      @customer.phone2 = params["phone2"]
      @customer.email = params["contact_email"]
      @customer.groom_name = params["groom_name"]
      @customer.groom_phone = params["groom_phone"]
      @customer.groom_email = params["groom_email"]
      @customer.address = params["address"]
      @customer.city = params["city"]
      @customer.state = params["state"]
      @customer.zip = params["zip"]
      @customer.notes = params["notes"]
        if @customer.save
        else
          render(:cust_edit) and return
        end
    elsif params["delete"]
      event = Event.where(id: params["delete"]).first
      event.destroy
      for each in DesignedProduct.where(event_id: params["delete"])
        each.destroy
      end  
      for specification in Specification.where(event_id: params["delete"])
        specification.destroy    
      end
      deleted_quote = Quote.where(event_id: params["delete"]).first
      if deleted_quote != nil
        deleted_quote.destroy
      else
      end    
    end
    redirect_to "/cust_edit/#{cust_id}" and return
  end
  
######### EVENT NEW

### GET Handler from cust_edit.erb
  def event_new
    cust_id = params["cust_id"]
    @customer = Customer.where(florist_id: session["found_florist_id"]).where(id: cust_id).first
    @event = Event.new
    @employee_list = [""] + Employee.where(florist_id: session["found_florist_id"]).where(status: "Active").uniq.pluck(:name)
    render(:event_new) and return
  end

### POST Handler from event_new.erb
  def create_new_event
   
    @event = Event.new
    @event.name = params["event_name"]
    #@event.date_of_event = params["event_date"]
    @event.date_of_event = Date.civil(params[:event_date]["element(1i)"].to_i, params[:event_date]["element(2i)"].to_i, params[:event_date]["element(3i)"].to_i)

    
    @event.time = params["event_time"]
    @event.delivery_setup_time = params["setup_time"]
    @event.feel_of_day = params["feel_of_day"]
    @event.color_palette = params["color_palette"]
    @event.flower_types = params["flower_types"]
    @event.attire = params["attire"]
    @event.photographer = params["photographer"]
    @event.coordinator = params["coordinator"]
    @event.locations = params["locations"]
      if params["lead_designer"] != ""
        @event.employee_id = Employee.where(name: params["lead_designer"]).where(florist_id: session["found_florist_id"]).first.id                                                   
      else
        @event.employee_id = nil
      end
    @event.florist_id = session["found_florist_id"]                                                                        #As well, you need to resolve the 3rd party and Site info
    @event.budget = params["budget"]
    @event.notes = params["notes"]
    @event.customer_id = params["customer_id"]  # How Do I make non-editable elements of a form. IE:  Shouldn't be able to edit ID #s
    @event.event_status = "Open Proposal"
    if @event.save
      redirect_to "/event_edit/#{@event.id}" and return
    else
      @customer = Customer.where(id: params["customer_id"]).first
      @employee_list = [""] + Employee.where(florist_id: session["found_florist_id"]).where(status: "Active").uniq.pluck(:name)
      render(:event_new) and return
    end
  end

########## EDIT EVENT
###GET Handler from event_new.erb
  def event_edit
    event_id = params["event_id"]
    @event = Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first
    @specifications = @event.specifications.order("id")
    @employee_list = Employee.where(florist_id: session["found_florist_id"]).where(status: "Active").uniq.pluck(:name)
    render(:event_edit) and return
  end
  
###POST Handler from event_edit.erb
  def event_and_specs_edit
    #Updates to Event Section
      @event = Event.where(id: params["event_id"]).first
      @event.name = params["event_name"]
      @event.date_of_event = params["event_date"]
      @event.time = params["event_time"]
      @event.delivery_setup_time = params["setup_time"]
      @event.feel_of_day = params["feel_of_day"]
      @event.color_palette = params["color_palette"]
      @event.flower_types = params["flower_types"]
      @event.attire = params["attire"]
      @event.photographer = params["photographer"]
      @event.coordinator = params["coordinator"]
      @event.locations = params["locations"]
      @event.employee_id = Employee.where(name: params["lead_designer"]).where(florist_id: session["found_florist_id"]).first.id                                                   
                                                                            #As well, you need to resolve the 3rd party and Site info
      @event.notes = params["notes"]
      @event.budget = params["budget"]
      @event.customer_id = params["customer_id"]  
      if @event.save == false
        @employee_list = Employee.where(florist_id: session["found_florist_id"]).where(status: "Active").uniq.pluck(:name)
        @specifications = @event.specifications.order("id")
        render(:event_edit) and return
      else # do nothing
      end
    #Updates to Event Specifications Section
      for each in Specification.where(event_id: params["event_id"])  
        each.item_name = params["spec_item-#{each.id}"]
        each.item_quantity = params["spec_qty-#{each.id}"].to_i * 100.0
        each.item_specs = params["spec_notes-#{each.id}"]
        each.save      
      end
    if params["delete"]
        spec_id = params["delete"]
        spec = Specification.where(id: spec_id).first
        spec.destroy
        designed_products = DesignedProduct.where(specification_id: spec_id)
      for each in designed_products
        each.destroy
      end  
    elsif params["add"]
      new_spec = Specification.new
      new_spec.event_id = params["ev_id"]
      new_spec.item_quantity = 1 * 100.0
      new_spec.item_name = ""
      new_spec.florist_id = session["found_florist_id"] 
      new_spec.save!
    else #do nothing
    end
    redirect_to "/event_edit/#{params["event_id"]}" and return
 
    end
  
  
########## VIRTUAL STUDIO

###GET Handler from event_edit.erb
  def virtual_studio
    event_id = params["event_id"]    
    @event= Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first  
    @specifications = @event.specifications.order("id")
  
  if @specifications == []
    
      flash[:error] = "A. You need to create arrangements below before designing them in Virtual Studio."
      redirect_to "/event_edit/#{params["event_id"]}" and return
    
    
    else
    end
  
  
  
  
  
  
  
  
  #Creates a list of used products for the specification 
    designedproducts = DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: event_id)
    used_products = []
    for each in designedproducts
      used_products << each.product.name
    end
    @list_of_products = used_products.uniq.sort

  #Creates a new designed_product for each specification for each product identified for the particular specification
  #This addresses the issue associated specifications added at the end of the design process.
   for each in @list_of_products
      id = Product.where(name: each).where(florist_id: session["found_florist_id"]).first.id
      for specification in @specifications
          x = DesignedProduct.where(product_id: id).where(specification_id: specification.id).first
          if x == nil
            new_dp = DesignedProduct.new
            new_dp.specification_id = specification.id
            new_dp.product_id = id
            new_dp.event_id = @event.id
            new_dp.product_qty = 0
            new_dp.florist_id = session["found_florist_id"]
            #new_dp.product_type = Product.where(name: each).where(florist_id: session["found_florist_id"]).first.product_type
            new_dp.save!
          else
          end
      end
    end
  
  ## Generate dropdown list for adding new products to the Virtual Studio Page
    products = Product.where(status: "Active").where(florist_id: session["found_florist_id"]).order("name")
    dropdown = []
    for product in products
      dropdown << product.name
    end
    for item in @list_of_products
      dropdown = dropdown - [item]
    end
    @dropdown = dropdown
    render(:virtual_studio) and return
end


  
### POST Handler from virtual_studio.erb
  # Updates Virtual Studio Page based on updates made by user. 
  def virtual_studio_update
    event_id = params["event_id"]
    specifications = Specification.where(event_id: event_id).order("id")
    designedproducts = DesignedProduct.where(event_id: event_id)
    for each in designedproducts
      for specification in specifications
        if params["stemcount_#{each.id}"].to_f*100 != each.product_qty
          each.product_qty = params["stemcount_#{each.id}"].to_f * 100.round(2)
          #each.product_type = Product.where(id: each.product_id).first.product_type  
          each.save!
        end
      end
    end  
    
    if params["add"]
      new_item = params["new_item"]
      specifications = Specification.where(event_id: event_id)
      for specification in specifications
        new_dp = DesignedProduct.new
        new_dp.specification_id = specification.id
        new_dp.product_qty = 0
       # new_dp.product_type = Product.where(name: new_item).where(florist_id: session["found_florist_id"]).first.product_type
        new_dp.florist_id = session["found_florist_id"]
        new_dp.product_id = Product.where(name: new_item).where(florist_id: session["found_florist_id"]).first.id
        new_dp.event_id = event_id
        new_dp.save!
      end         
    elsif params["remove"]
      removed_product_id = params["remove"]
      removed_items = DesignedProduct.where(event_id: event_id).where(product_id: removed_product_id)
      for each_item in removed_items
        each_item.destroy
      end
    else # do nothing
    end
    redirect_to "/virtual_studio/#{event_id}" and return
  end
  
  
### GET Handler from virtual_studio.erb 
  def popup_specs
    event_id = params["event_id"]
    @event_id = event_id
    @specifications = Specification.where(florist_id: session["found_florist_id"]).where(event_id: event_id).order("id")
    render(:popup_specs, layout:false) and return
  end 
  
######### QUOTE GENERATION

### GET handler from event_edit.erb
  def quote_generation
    event_id = params["event_id"]
    @event = Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first
    @specifications = @event.specifications.order("id")
    count = 0
    for each in DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: event_id)
      count = count + (each.product_qty / 100.0)
    end
    if DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first == nil || count < 1.0
    
      flash[:error] = "B. You need to create arrangements below and then design them in the Virtual Studio before viewing the Quote or Design Day Details."
      redirect_to "/event_edit/#{params["event_id"]}" and return
    
    
    else
    end
    if Quote.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first == nil
      new_quote = Quote.new
      new_quote.quote_name = @event.name
      new_quote.event_id = event_id
      new_quote.status = "Open Proposal"
      new_quote.florist_id = session["found_florist_id"] 
      new_quote.total_price = 0
      new_quote.markup = 0
      new_quote.save!
      event = Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first
      event.event_status = "Open Proposal"
      event.save!
    else
    end
    @quote = Quote.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first
     
    render(:gen_quote) and return
  end

### POST handler from gen_quote.erb
  def save_quote
    event_id = params["event_id"]
    for each in Specification.where(event_id: event_id)
      if params["quoted_price-#{each.id}"] == nil
        each.quoted_price = 0
      else
        each.quoted_price = params["quoted_price-#{each.id}"].to_f * 100
      end
      each.per_item_cost = params["per_item_cost-#{each.id}"].to_f * 100
      each.per_item_list_price = params["per_item_list_price-#{each.id}"].to_f * 100
      each.extended_list_price = params["extended_list_price-#{each.id}"].to_f * 100
      each.save!
    end
    quote = Quote.where(event_id: event_id).first
    quote.quote_name = params["quote_name"]
    quoted_total_price = 0
    total_cost = 0
    for each in Specification.where(event_id: event_id)
      if each.quoted_price == nil
        each.quoted_price = 0
      
      else
      end
      quoted_total_price = quoted_total_price + each.quoted_price
      total_cost = total_cost + ((each.per_item_cost / 100.0) * (each.item_quantity / 100.0))
    end 
    quote.total_price = quoted_total_price
    if total_cost != 0
      quote.markup = (quote.total_price / total_cost)
    else
    end
    quote.status = params["status"]
    if params["status"] != "Completed"  && params["status"] != "Ordered"
      quote.wholesale_order_date = nil
    else
    end
    quote.save!
    event = Event.where(id: event_id).first
    event.event_status = params["status"]
    event.save!
    redirect_to "/generate_quote/#{event_id}" and return
    end

### GET Handler from gen_quote.erb
  def generate_cust_facing_quote
    event_id = params["event_id"]
    @event = Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first
    @specifications = @event.specifications.order("id")
    if DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first == nil
      
      redirect_to "/virtual_studio/#{event_id}" and return
    else
    end
    if Quote.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first == nil
      new_quote = Quote.new
      new_quote.event_id = event_id
      new_quote.status = "Open Proposal"
      new_quote.florist_id = session["found_florist_id"] 
      new_quote.save!
      event = Event.where(florist_id: session["found_florist_id"]).where(id: event_id).first
      event.event_status = "Open Proposal"
      event.save!
    else
    end
    @quote = Quote.where(florist_id: session["found_florist_id"]).where(event_id: event_id).first
    render(:cust_facing_quote, layout:false) and return
  end
  
######### WHOLESALE ORDERS & DESIGN DAY DETAILS
###GET Handler from homepage.erb
  def schedule_order_date
    @booked_quotes = Quote.where(florist_id: session["found_florist_id"]).where(status: "Ordered").where(wholesale_order_date: nil) + Quote.where(florist_id: session["found_florist_id"]).where(status: "Booked").where(wholesale_order_date: nil)
    render(:schedule_order_date) and return
  end
  
###POST Handler from schedule_order_date.erb
  def assign_order_date
    @booked_quotes = Quote.where(florist_id: session["found_florist_id"]).where(status: "Ordered").where(wholesale_order_date: nil) + Quote.where(florist_id: session["found_florist_id"]).where(status: "Booked").where(wholesale_order_date: nil)
    for booked_quote in @booked_quotes
      if params["place_order-#{booked_quote.id}"]
        booked_quote.status = "Ordered"
        #booked_quote.wholesale_order_date = Date.civil(params[:place_order_on]["element(1i)"].to_i, params[:place_order_on]["element(2i)"].to_i, params[:place_order_on]["element(3i)"].to_i)
        booked_quote.wholesale_order_date = params["place_order_on"]
        
        booked_quote.save!
      else
      end
    end
      redirect_to "/wholesale_order_list/#{params["place_order_on"]}" and return
  end

###GET Handler from schedule_order_date.erb
  #Creates a "grocery list" of all products, etc. that will need to be ordered from the wholesaler.
  def wholesale_order_list
    @orders = Quote.where(florist_id: session["found_florist_id"]).where(status: "Ordered").where(wholesale_order_date: params["place_order_on"])
    @list_of_event_ids = @orders.uniq.pluck(:event_id)
    
    
    list_of_product_ids = []
    list_of_product_types = []
    for each_id in @list_of_event_ids   
      for designed_product in DesignedProduct.where(event_id: each_id)
        list_of_product_ids << designed_product.product_id
        list_of_product_types << designed_product.product.product_type
      end
    end
    @list_of_product_ids = list_of_product_ids.uniq
    @list_of_product_types = list_of_product_types.uniq.sort
    
    render(:wholesale_order_list) and return
  end
  
  
=begin
  @designed_products = DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"])
    @list_of_product_ids = @designed_products.uniq.pluck(:product_id)
    @list_of_product_types = @designed_products.uniq.pluck(:product_type).sort!
  
=end
  
  
  
  
  
  
  
####GET Handler from event_edit.erb
  #Creates an order details summary for the individual event (to be used on the day of the design work).
  def design_day_details
    @event = Event.where(florist_id: session["found_florist_id"]).where(id: params["event_id"]).first
    @quote = Quote.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"]).first
    @specifications = Specification.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"])
    @designed_products = DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"])
    @list_of_product_ids = @designed_products.uniq.pluck(:product_id)
    product_types = []
    for id in @list_of_product_ids
      product_types = product_types + [Product.where(id: id).first.product_type]
    end
    @list_of_product_types = product_types.uniq.sort!

    count = 0
    for each in @designed_products
      count = count + (each.product_qty / 100.0)
    end

    if DesignedProduct.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"]).first == nil || count < 1.0
      flash[:error] = "C. You need to create arrangements below and then design them in the Virtual Studio before viewing the Quote or Design Day Details."
      redirect_to "/event_edit/#{params["event_id"]}" and return
    end

    if Quote.where(florist_id: session["found_florist_id"]).where(event_id: params["event_id"]).first == nil
      flash[:error] = "D. You need to create a Quote before viewing the Design Day Details."
      redirect_to "/event_edit/#{params["event_id"]}" and return
    end
    render(:design_day_details) and return
  end

######### PRODUCTS
### GET Handler from homepage.erb
  def products
    @products = Product.where(florist_id: session["found_florist_id"]).order("status", "product_type", "name") 
    @PRODUCT_UPDATE_MUST_HAVE = PRODUCT_UPDATE_MUST_HAVE
    render(:products) and return
  end

### POST Handler from products.erb
  def product_post
    if params["new"] 
      redirect_to "/product/new" and return
    else
      redirect_to "/product/#{params["edit"]}" and return
    end
  end

### GET Handler from product_post.erb
  def product
    if PRODUCT_UPDATE_MUST_HAVE.include?(Employee.where(id: session["found_user_id"]).first.admin_rights)
      id = params["product_id"]
      if id == "new"
        @product = Product.new
        @product.cost_per_bunch = 0
        @product.items_per_bunch = 0
        @product.markup = 0
      else
        @product = Product.where(florist_id: session["found_florist_id"]).where(id: id).first
      end
      render(:product_updates) and return
    else
      redirect_to "/products" and return
    end
  
  end

### POST Handler from new_product.erb
  def product_updates
    if params["product_id"] == "new"
      @product = Product.new
      @product.florist_id = session["found_florist_id"]      
    else
      @product = Product.where(id: params["product_id"]).first
    end
     @product.product_type= params["product_type"]
    @product.name = params["product_name"]
    @product.items_per_bunch = params["items_per_bunch"].to_f * 100
    @product.cost_per_bunch = params["cost_per_bunch"].to_f * 100
    @product.cost_for_one =(params["cost_per_bunch"].to_f) / (params["items_per_bunch"].to_f) * 100
    @product.markup = params["markup"].to_f * 100
    @product.status = params["status"]
    @product.updated_by = Employee.where(id: session["found_user_id"]).first.name
    @product.florist_id = session["found_florist_id"]
    if @product.save
      redirect_to "/products" and return
    else
      render(:product_updates) and return
    end    
  end



######### EMPLOYEES
### GET Handler from homepage.erb
  def employees
    if EMPLOYEES_VIEW_MUST_HAVE.include?(Employee.where(id: session["found_user_id"]).first.admin_rights)
    @employees = Employee.where(florist_id: session["found_florist_id"]).order("status",  "name")
    render(:employees) and return
    else
    redirect_to "/employee/#{session["found_user_id"]}" and return
    end
  end

### POST Handler from employees.erb
  def employee_post
    if params["new"] 
      redirect_to "/employee/new" and return
    else
      redirect_to "/employee/#{params["edit"]}" and return
    end
  end

### GET Handler from employees.erb
  def employee
    id = params["employee_id"]
    @ADMIN_RIGHTS = ADMIN_RIGHTS
    @EMPLOYEES_VIEW_MUST_HAVE = EMPLOYEES_VIEW_MUST_HAVE 
    if id == "new"
      @employee = Employee.new
      @employee.view_pref = "all"
    else
      @employee = Employee.where(florist_id: session["found_florist_id"]).where(id: id).first
    end
    render(:employee_edit) and return
  end

### POST Handler from employee_edit.erb
  def employee_updates
    if params["employee_id"] == "new"
      @employee = Employee.new
      @employee.florist_id = session["found_florist_id"]
      @employee.view_pref = "all"
    else
      @employee = Employee.where(id: params["employee_id"]).first
    end
    @employee.name = params["name"]
    @employee.status = params["status"]
    @employee.email = params["email"]
    @employee.w_phone = params["phone_w"]
    @employee.c_phone = params["phone_c"]
   
    @employee.username = params["username"]
    @employee.password = params["password"]
    @employee.password_confirmation = params["password_confirmation"]
    @employee.admin_rights = params["admin_rights"]
    if @employee.save
      if EMPLOYEES_VIEW_MUST_HAVE.include?(Employee.where(id: session["found_user_id"]).first.admin_rights)
        redirect_to "/employees" and return
      else
        redirect_to home_path and return
      end
    else
       
    @ADMIN_RIGHTS = ADMIN_RIGHTS
    @EMPLOYEES_VIEW_MUST_HAVE = EMPLOYEES_VIEW_MUST_HAVE 
   
      render(:employee_edit) and return
    end
  end

end

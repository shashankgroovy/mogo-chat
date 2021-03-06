App.AuthenticatedRoute = Em.Route.extend
  beforeModel: (transition)->
    applicationController = @controllerFor("application")
    if applicationController.get("currentUser")
      return true

    Em.$.getJSON("/api/sessions").then (response)=>
      if response.user
        userAttributes =
          id: response.user.id,
          name: response.user.name,
          role: response.user.role
          email: response.user.email
          authToken: response.user.auth_token
          color: App.paintBox.getColor()

        if @store.recordIsLoaded("user", userAttributes.id)
          @store.find("user", userAttributes.id).then (user)=>
            @controllerFor("application").set("currentUser", user)
        else
          userAttributes["color"] = App.paintBox.getColor()
          user = @store.push("user", userAttributes)
          @controllerFor("application").set("currentUser", user)
      else
        @redirectToLogin(transition)

  # Redirect to the login page and store the current transition so we can
  # run it again after login
  redirectToLogin: (transition)->
    loginController = @controllerFor("login")
    # loginController.set("attemptedTransition", transition)
    @transitionTo("login")

  #TODO not sure why this is here
  actions:
    error: (reason, transition)->
      console.log "ERROR: moving to login", error
      this.redirectToLogin(transition)

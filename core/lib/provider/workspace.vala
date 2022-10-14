namespace GenesisShell {
  internal sealed class WorkspaceProvider : GLib.Object, IWorkspaceProvider {
    public Context context { get; construct; }

    internal WorkspaceProvider(Context context) {
      Object(context: context);
    }

    public Workspace? create_workspace(string name) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var workspace_provider = plugin.container.get(typeof (IWorkspaceProvider)) as IWorkspaceProvider;
        if (workspace_provider == null) continue;

        var workspace = workspace_provider.create_workspace(name);
        if (workspace == null) continue;
        return workspace;
      }
      return null;
    }

    public unowned Workspace? get_workspace(WorkspaceID id) {
      foreach (var plugin in this.context.plugins.get_values()) {
        var workspace_provider = plugin.container.get(typeof (IWorkspaceProvider)) as IWorkspaceProvider;
        if (workspace_provider == null) continue;

        unowned var workspace = workspace_provider.get_workspace(id);
        if (workspace == null) continue;
        return workspace;
      }
      return null;
    }

    public GLib.List<WorkspaceID?> get_workspace_ids() {
      var list = new GLib.List<WorkspaceID?>();

      foreach (var plugin in this.context.plugins.get_values()) {
        var workspace_provider = plugin.container.get(typeof (IWorkspaceProvider)) as IWorkspaceProvider;
        if (workspace_provider == null) continue;

        var sublist = workspace_provider.get_workspace_ids();
        foreach (var id in sublist) {
          if (list.find(id) != null) continue;

          list.append(id);
        }
      }
      return list;
    }
  }
}

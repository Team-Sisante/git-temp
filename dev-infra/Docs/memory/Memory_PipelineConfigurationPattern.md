# Pipeline Configuration Pattern: Adding Diagnostic Steps

To add diagnostic tasks (like network checks) to a GoCD pipeline managed via `cruise-config.xml`, follow this pattern:

1.  **Create a portable script:** Ensure your diagnostic script (e.g., `Scripts/diagnose-network.sh`) is executable (`chmod +x`) and committed to the repository.
2.  **Inject into `cruise-config.xml`:** Locate the specific pipeline and job within `gocd-server/config/cruise-config.xml`.
3.  **Add the command:** Add a new `<exec>` task within the `<tasks>` block of the relevant job *before* the main action task.

Example:
```xml
<tasks>
  <!-- Run diagnostic script first -->
  <exec command="bash">
    <arg>-c</arg>
    <arg>/badminton_court/Scripts/diagnose-network.sh</arg>
  </exec>

  <!-- Main action task -->
  <exec command="bash">
    <arg>-c</arg>
    <arg><![CDATA[
      export GITHUB_TOKEN='__GITHUB_TOKEN__'
      node /badminton_court/Scripts/build-and-push.js
    ]]></arg>
  </exec>
</tasks>
```

Using this approach keeps the diagnostic logic in version control and ensures it runs consistently across pipeline executions.

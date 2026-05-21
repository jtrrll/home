_: {
  config.perSystem =
    { pkgs, ... }:
    {
      config.terranix.terranixConfigurations.github-tf = {
        workdir = ".terraform/github";
        terraformWrapper.package = pkgs.opentofu.withPlugins (p: [ p.integrations_github ]);
        modules = [
          {
            terraform.required_providers.github = {
              source = "integrations/github";
              version = "~> 6.0";
            };

            provider.github = {
              owner = "jtrrll";
              token = "\${var.github_token}";
            };

            variable = {
              github_token = {
                type = "string";
                sensitive = true;
                description = "GitHub personal access token with repo admin permissions";
              };
              pr_bot_token = {
                type = "string";
                sensitive = true;
                description = "GitHub PAT for the PR bot to create/merge PRs";
              };
            };

            resource = {
              github_repository.home = {
                name = "home";
                description = "jtrrll's home automation and infrastructure";
                visibility = "public";

                has_issues = true;
                has_projects = false;
                has_wiki = false;
                has_discussions = false;

                allow_merge_commit = false;
                allow_squash_merge = true;
                allow_rebase_merge = false;
                allow_auto_merge = true;
                allow_update_branch = true;
                delete_branch_on_merge = true;

                topics = [
                  "home-automation"
                  "home-infrastructure"
                  "nix"
                  "nixos"
                ];
              };

              github_branch_default.main = {
                repository = "\${github_repository.home.name}";
                branch = "main";
              };

              github_repository_vulnerability_alerts.home = {
                repository = "\${github_repository.home.name}";
              };

              github_repository_ruleset.main = {
                name = "main";
                repository = "\${github_repository.home.name}";
                target = "branch";
                enforcement = "active";

                conditions = {
                  ref_name = {
                    include = [ "~DEFAULT_BRANCH" ];
                    exclude = [ ];
                  };
                };

                rules = {
                  deletion = true;
                  non_fast_forward = true;
                  required_linear_history = true;
                };
              };

              github_repository_ruleset.pull_requests = {
                name = "pull-requests";
                repository = "\${github_repository.home.name}";
                target = "branch";
                enforcement = "active";

                conditions = {
                  ref_name = {
                    include = [ "~DEFAULT_BRANCH" ];
                    exclude = [ ];
                  };
                };

                rules = {
                  pull_request = {
                    dismiss_stale_reviews_on_push = false;
                    required_approving_review_count = 0;
                    require_last_push_approval = false;
                  };
                };
              };

              github_actions_secret.pr_bot_token = {
                repository = "\${github_repository.home.name}";
                secret_name = "PR_BOT_PERSONAL_ACCESS_TOKEN";
                value = "\${var.pr_bot_token}";
              };
            };

            output.url = {
              value = "\${github_repository.home.html_url}";
            };
          }
        ];
      };
    };
}

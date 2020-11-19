\c openmrs_metrics
UPDATE github
SET metrics = (
  CASE type
    WHEN 'CreateEvent' THEN jsonb_build_object(
      'ref', data->'payload'->>'ref',
      'ref_type', data->'payload'->>'ref_type',
      'description', replace(data->'payload'->>'description',E'\n','\n'))
    WHEN 'DeleteEvent' THEN jsonb_build_object(
      'ref', data->'payload'->>'ref',
      'ref_type', data->'payload'->>'ref_type')
    WHEN 'ForkEvent' THEN jsonb_build_object(
      'url', data->'payload'->'forkee'->>'url',
      'name', data->'payload'->'forkee'->>'name',
      'owner', data->'payload'->'forkee'->'owner'->>'login')
    WHEN 'GollumEvent' THEN jsonb_build_object(
		'pages', (SELECT jsonb_agg(pages - 'sha' - 'summary')
      FROM jsonb_array_elements(data->'payload'->'pages') pages))
    WHEN 'IssuesEvent' THEN jsonb_build_object(
      'url', data->'payload'->'issue'->>'url',
      'state', data->'payload'->'issue'->>'state',
      'title', data->'payload'->'issue'->>'title',
      'number', data->'payload'->'issue'->>'number',
      'assignees', jsonb_path_query_array(data->'payload'->'issue'->'assignees', '$.login'),
      'html_url', data->'payload'->'issue'->>'html_url',
      'action', data->'payload'->>'action')
    WHEN 'MemberEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action',
      'member', data->'payload'->'member'->>'login')
    WHEN 'PullRequestEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action',
      'pr_number', data->'payload'->>'number',
      'pr_url', data->'payload'->'pull_request'->>'url',
      'user', data->'payload'->'pull_request'->'user'->>'login',
      'pr_title', data->'payload'->'pull_request'->>'title',
      'requested_reviewers', jsonb_path_query_array(
        data->'payload'->'pull_request'->'requested_reviewers', '$.login'),
      'pr_state', data->'payload'->'pull_request'->>'state',
      'pr_merged', data->'payload'->'pull_request'->>'merged',
      'pr_commits', data->'payload'->'pull_request'->>'commits',
      'comments', data->'payload'->'pull_request'->>'comments',
      'diff_url', data->'payload'->'pull_request'->>'diff_url',
      'html_url', data->'payload'->'pull_request'->>'html_url',
      'issue_url', data->'payload'->'pull_request'->>'issue_url',
      'pr_created_at', data->'payload'->'pull_request'->>'created_at',
      'pr_updated_at', data->'payload'->'pull_request'->>'updated_at',
      'changed_files', data->'payload'->'pull_request'->>'changed_files',
      'additions', data->'payload'->'pull_request'->>'additions',
      'deletions', data->'payload'->'pull_request'->>'deletions',
      'review_comments', data->'payload'->'pull_request'->>'review_comments',
      'mergeable_state', data->'payload'->'pull_request'->>'mergeable_state')
    WHEN 'PullRequestReviewCommentEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action',
      'user', data->'payload'->'comment'->'user'->>'login',
      'html_url', data->'payload'->'comment'->>'html_url',
      'pr_number', data->'payload'->'pull_request'->>'number',
      'pr_url', data->'payload'->'pull_request'->>'url',
      'pr_title', data->'payload'->'pull_request'->>'title')
    WHEN 'PullRequestReviewEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action',
      'user', data->'payload'->'review'->'user'->>'login',
      'review_state', data->'payload'->'review'->>'state',
      'html_url', data->'payload'->'review'->>'html_url',
      'commit_id', data->'payload'->'review'->>'commit_id',
      'submitted_at', data->'payload'->'review'->>'submitted_at',
      'pr_number', data->'payload'->'pull_request'->>'number',
      'pr_url', data->'payload'->'pull_request'->>'url',
      'pr_html_url', data->'payload'->'pull_request'->>'html_url',
      'pr_title', data->'payload'->'pull_request'->>'title',
      'requested_reviewers', jsonb_path_query_array(
        data->'payload'->'pull_request'->'requested_reviewers', '$.login'),
      'pr_state', data->'payload'->'pull_request'->>'state',
      'pr_merged', data->'payload'->'pull_request'->>'merged',
      'pr_commits', data->'payload'->'pull_request'->>'commits',
      'issue_url', data->'payload'->'pull_request'->>'issue_url',
      'pr_created_at', data->'payload'->'pull_request'->>'created_at',
      'pr_updated_at', data->'payload'->'pull_request'->>'updated_at',
      'changed_files', data->'payload'->'pull_request'->>'changed_files')
    WHEN 'PushEvent' THEN (
      CASE data->'payload' ? 'shas'
        WHEN true THEN jsonb_build_object(
          'size', data->'payload'->>'size',
          'distinct_size', jsonb_array_length(data->'payload'->'shas'),
          'commits', (
            SELECT jsonb_agg(jsonb_build_object(
              'email', commit->>1,
              'message', replace(commit->>2,E'\n','\n'),
              'name', commit->>3))
            FROM jsonb_array_elements(data->'payload'->'shas') commits (commit)))
        ELSE jsonb_build_object(
          'size', data->'payload'->>'size',
          'distinct_size', data->'payload'->>'distinct_size',
          'commits', (
            SELECT jsonb_agg(jsonb_build_object(
              'url', commit->'url',
              'name', commit->'author'->>'name',
              'email', commit->'author'->>'email',
              'message', replace(commit->>'message', E'\n', '\n')))
            FROM
              jsonb_array_elements(data->'payload'->'commits') commits (commit)))
      END)
    WHEN 'ReleaseEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action',
      'url', data->'payload'->'release'->>'url',
      'html_url', data->'payload'->'release'->>'html_url',
      'name', data->'payload'->'release'->>'name',
      'tag_name', data->'payload'->'release'->>'tag_name',
      'pre_release', data->'payload'->'release'->>'pre_release',
      'draft', data->'payload'->'release'->>'draft',
      'author', data->'payload'->'release'->'author'->>'login')
    WHEN 'TeamAddEvent' THEN jsonb_build_object(
      'team_name', data->'payload'->'team'->>'name',
      'team_slug', data->'payload'->'team'->>'slug',
      'permission', data->'payload'->'team'->>'permission',
      'repo_name', data->'payload'->'repository'->>'name',
      'repo_url', data->'payload'->'repository'->>'url',
      'repo_owner', data->'payload'->'repository'->'owner'->>'login')
    WHEN 'WatchEvent' THEN jsonb_build_object(
      'action', data->'payload'->>'action')
    ELSE null
  END
);
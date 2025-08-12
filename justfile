# Start development server with hot reload
serve:
    hugo server --buildDrafts --buildFuture

# Build the site for production
build:
    hugo --minify

# Create a new blog post
new-post title:
    hugo new content/blog/{{title}}.md

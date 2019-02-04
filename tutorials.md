---
layout: page
title: "Microservices with Spring"
subtitle: Spring Boot, Spring Cloud and Web Development tutorials
css: "/css/index.css"
meta-title: "Spring Boot, Spring Cloud and Web Development tutorials"
meta-description: "Tutorial on Spring Boot and Spring Cloud Technology"
---
<div class="list-filters">
   <a href="/" class="list-filter">All posts</a> <a
      href="/popular" class="list-filter">Most Popular</a> <a
      href="/tutorials" class="list-filter filter-selected">Tutorials</a> <a 
	  href="/tags" class="list-filter">Index</a>
</div>
<div class="posts-list">
   {% for post in site.tags.tutorial %}
   <article>
      <a class="post-preview" href="{{ post.url | prepend: site.baseurl }}">
         <h2 class="post-title">{{ post.title }}</h2>
         {% if post.subtitle %}
         <h3 class="post-subtitle">{{ post.subtitle }}</h3>
         {% endif %}
         <p class="post-meta">Posted on {{ post.date | date: "%B %-d, %Y" }}
            {% if post.lastupdated %}
            | Last updated on {{ post.lastupdated | date: "%B %-d, %Y" }}
            {% endif %}
         </p>
         <div class="post-entry">
            {{ post.preview-message | truncatewords: post.preview-length | strip_html | xml_escape}} <span
               href="{{ post.url | prepend: site.baseurl }}"
               class="post-read-more">[Read&nbsp;More]</span>
         </div>
      </a>
   </article>
   {% endfor %}
</div>
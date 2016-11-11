<%inherit file="../layouts/main.mako"/>
<%!
    import os
    import datetime
    import urllib
    import ntpath

    import sickrage
    from sickrage.core.updaters import tz_updater
    from sickrage.core.searchers import subtitle_searcher
    from sickrage.core.common import SKIPPED, WANTED, UNAIRED, ARCHIVED, IGNORED, FAILED, DOWNLOADED
    from sickrage.core.common import Quality, qualityPresets, statusStrings, Overview
    from sickrage.core.helpers import anon_url, srdatetime, pretty_filesize, get_size
    from sickrage.core.media.util import showImage
    from sickrage.indexers import srIndexerApi
%>
<%block name="content">
    <%namespace file="../includes/quality_defaults.mako" import="renderQualityPill"/>
    <div class="pull-left form-inline">
        Change Show:
        <div class="navShow"><img id="prevShow" src="/images/prev.png" alt="&lt;&lt;" title="Prev Show"/></div>
        <select id="pickShow" class="form-control form-control-inline input-sm">
            % for curShowList in sortedShowLists:
                <% curShowType = curShowList[0] %>
                <% curShowList = curShowList[1] %>

                % if len(sortedShowLists) > 1:
                    <optgroup label="${curShowType}">
                % endif
                % for curShow in curShowList:
                    <option value="${curShow.indexerid}" ${('', 'selected="selected"')[curShow == show]}>${curShow.name}</option>
                % endfor
                % if len(sortedShowLists) > 1:
                    </optgroup>
                % endif
            % endfor
        </select>
        <div class="navShow"><img id="nextShow" src="/images/next.png" alt="&gt;&gt;" title="Next Show"/></div>
    </div>

    <div class="clearfix"></div>

    <div id="showtitle" data-showname="${show.name}">
        <h1 class="title" id="scene_exception_${show.indexerid}"
            data-tooltip="${all_scene_exceptions}">${show.name}</h1>
    </div>

    % if seasonResults:
        ##There is a special/season_0?##
        % if int(seasonResults[-1]) == 0:
                    <% season_special = 1 %>
        % else:
                    <% season_special = 0 %>
        % endif
        % if not sickrage.srCore.srConfig.DISPLAY_SHOW_SPECIALS and season_special:
            <% lastSeason = seasonResults.pop(-1) %>
        % endif
        <span class="h2footer displayspecials pull-right">
            % if season_special:
                Display Specials:
                <a class="inner"
                   href="/toggleDisplayShowSpecials/?show=${show.indexerid}">${('Show', 'Hide')[bool(sickrage.srCore.srConfig.DISPLAY_SHOW_SPECIALS)]}</a>
            % endif
        </span>

        <div class="h2footer pull-right">
            <span>
                % if (len(seasonResults) > 14):
                    <select id="seasonJump" class="form-control input-sm" style="position: relative; top: -4px;">
                        <option value="jump">Jump to Season</option>
                        % for seasonNum in seasonResults:
                            <option value="#season-${seasonNum}"
                                    data-season="${seasonNum}">${('Specials', 'Season ' + str(seasonNum))[int(seasonNum) > 0]}</option>
                        % endfor
                    </select>
                % else:
                    Season:
                % for seasonNum in seasonResults:
                    % if int(seasonNum) == 0:
                        <a href="#season-${seasonNum}">Specials</a>
                    % else:
                        <a href="#season-${seasonNum}">${str(seasonNum)}</a>
                    % endif
                    % if seasonNum != seasonResults[-1]:
                        <span class="separator">|</span>
                    % endif
                % endfor
                % endif
            </span>

        </div>
    % endif


    <div class="clearfix"></div>

    % if show_message:
        <div class="alert alert-info">
            ${show_message}
        </div>
    % endif

    <div id="container">
        <div id="posterCol">
            <a href="${showImage(show.indexerid, 'poster')}" rel="dialog" title="View Poster for ${show.name}"><img
                    src="${showImage(show.indexerid, 'poster_thumb')}" class="tvshowImg" alt=""/></a>
        </div>

        <div id="showCol">

            <div id="showinfo">
                % if 'rating' in show.imdb_info:
                <% rating_tip = str(show.imdb_info['rating']) + " / 10" + " Stars" + "<br />" + str(show.imdb_info['votes']) + " Votes" %>
                    <span class="imdbstars" data-tooltip="${rating_tip}">${show.imdb_info['rating']}</span>
                % endif

                <% _show = show %>
                % if not show.imdbid:
                    <span>(${show.startyear}) - ${show.runtime} minutes - </span>
                % else:
                % if 'country_codes' in show.imdb_info:
                    % for country in show.imdb_info['country_codes'].split('|'):
                        <img src="/images/blank.png" class="country-flag flag-${country}" width="16"
                             height="11" style="margin-left: 3px; vertical-align:middle;"/>
                    % endfor
                % endif
                % if 'year' in show.imdb_info:
                    <span>(${show.imdb_info['year']}) - ${show.imdb_info['runtimes']} minutes - </span>
                % endif
                    <a href="${anon_url('http://www.imdb.com/title/', _show.imdbid)}" rel="noreferrer"
                       onclick="window.open(this.href, '_blank'); return false;"
                       title="http://www.imdb.com/title/${show.imdbid}"><img alt="[imdb]" height="16" width="16"
                                                                             src="/images/imdb.png"
                                                                             style="margin-top: -1px; vertical-align:middle;"/></a>
                % endif
                <a href="${anon_url(srIndexerApi(_show.indexer).config['show_url'], _show.indexerid)}"
                   onclick="window.open(this.href, '_blank'); return false;"
                   title="${srIndexerApi(show.indexer).config["show_url"] + str(show.indexerid)}"><img
                        alt="${srIndexerApi(show.indexer).name}" height="16" width="16"
                        src="/images/${srIndexerApi(show.indexer).config["icon"]}"
                        style="margin-top: -1px; vertical-align:middle;"/></a>
                % if xem_numbering or xem_absolute_numbering:
                    <a href="${anon_url('http://thexem.de/search?q=', _show.name)}" rel="noreferrer"
                       onclick="window.open(this.href, '_blank'); return false;"
                       title="http://thexem.de/search?q-${show.name}"><img alt="[xem]" height="16" width="16"
                                                                           src="/images/xem.png"
                                                                           style="margin-top: -1px; vertical-align:middle;"/></a>
                % endif
            </div>

            <div id="tags">
                <ul class="tags">
                    % if not show.imdbid and show.genre:
                        % for genre in show.genre[1:-1].split('|'):
                            <a href="${anon_url('http://trakt.tv/shows/popular/?genres=', genre.lower())}"
                               target="_blank" title="View other popular ${genre} shows on trakt.tv.">
                                <li>${genre}</li>
                            </a>
                        % endfor
                    % endif
                    % if 'year' in show.imdb_info:
                        % for imdbgenre in show.imdb_info['genres'].replace('Sci-Fi','Science-Fiction').split('|'):
                            <a href="${anon_url('http://trakt.tv/shows/popular/?genres=', imdbgenre.lower())}"
                               target="_blank" title="View other popular ${imdbgenre} shows on trakt.tv.">
                                <li>${imdbgenre}</li>
                            </a>
                        % endfor
                    % endif
                </ul>
            </div>

            <div id="summary">
                <table class="summaryTable pull-left">
                    <% anyQualities, bestQualities = Quality.splitQuality(int(show.quality)) %>
                <tr>
                    <td class="showLegend">Quality:</td>
                <td>
                    % if show.quality in qualityPresets:
                        ${renderQualityPill(show.quality)}
                    % else:
                        % if anyQualities:
                            <i>Allowed:</i> ${", ".join([capture(renderQualityPill, x) for x in sorted(anyQualities)])}${("", "<br>")[bool(bestQualities)]}
                        % endif
                        % if bestQualities:
                            <i>Preferred:</i> ${", ".join([capture(renderQualityPill, x) for x in sorted(bestQualities)])}
                        % endif
                    % endif

                    % if show.network and show.airs:
                        <tr>
                            <td class="showLegend">Originally Airs:</td>
                            <td>${show.airs} ${("<font color='#FF0000'><b>(invalid Timeformat)</b></font> ", "")[tz_updater.test_timeformat(show.airs)]}
                                on ${show.network}</td>
                        </tr>
                    % elif show.network:
                        <tr>
                            <td class="showLegend">Originally Airs:</td>
                            <td>${show.network}</td>
                        </tr>
                    % elif show.airs:
                        <tr>
                            <td class="showLegend">Originally Airs:</td>
                            <td>${show.airs} ${("<font color='#FF0000'><b>(invalid Timeformat)</b></font>", "")[tz_updater.test_timeformat(show.airs)]}</td>
                        </tr>
                    % endif
                    <tr>
                        <td class="showLegend">Show Status:</td>
                        <td>${show.status}</td>
                    </tr>
                    <tr>
                        <td class="showLegend">Default EP Status:</td>
                        <td>${statusStrings[show.default_ep_status]}</td>
                    </tr>
                    % if os.path.isdir(showLoc):
                        <tr>
                            <td class="showLegend">Location:</td>
                            <td>${showLoc}</td>
                        </tr>
                    % else:
                        <tr>
                            <td class="showLegend"><span style="color: red;">Location: </span></td>
                            <td><span style="color: red;">${showLoc}</span> (Missing)</td>
                        </tr>
                    % endif
                    <tr>
                        <td class="showLegend">Scene Name:</td>
                        <td>${(show.name, " | ".join(show.exceptions))[show.exceptions != 0]}</td>
                    </tr>

                    % if show.rls_require_words:
                        <tr>
                            <td class="showLegend">Required Words:</td>
                            <td>${show.rls_require_words}</td>
                        </tr>
                    % endif
                    % if show.rls_ignore_words:
                        <tr>
                            <td class="showLegend">Ignored Words:</td>
                            <td>${show.rls_ignore_words}</td>
                        </tr>
                    % endif
                    % if bwl and bwl.whitelist:
                        <tr>
                            <td class="showLegend">Wanted Group${("", "s")[len(bwl.whitelist) > 1]}:</td>
                            <td>${', '.join(bwl.whitelist)}</td>
                        </tr>
                    % endif
                    % if bwl and bwl.blacklist:
                        <tr>
                            <td class="showLegend">Unwanted Group${("", "s")[len(bwl.blacklist) > 1]}:</td>
                            <td>${', '.join(bwl.blacklist)}</td>
                        </tr>
                    % endif

                    <tr>
                        <td class="showLegend">Size:</td>
                        <td>${pretty_filesize(get_size(showLoc))}</td>
                    </tr>

                </table>

                <table style="width:180px; float: right; vertical-align: middle; height: 100%;">
                    <% info_flag = subtitle_searcher.fromietf(show.lang).opensubtitles if show.lang else '' %>
                    <tr>
                        <td class="showLegend">Info Language:</td>
                        <td><img src="/images/subtitles/flags/${info_flag}.png" width="16" height="11"
                                 alt="${show.lang}" title="${show.lang}"
                                 onError="this.onerror=null;this.src='/images/flags/unknown.png';"/></td>
                    </tr>
                    % if sickrage.srCore.srConfig.USE_SUBTITLES:
                        <tr>
                            <td class="showLegend">Subtitles:</td>
                            <td><img src="/images/${("no16.png", "yes16.png")[bool(show.subtitles)]}"
                                     alt="${("N", "Y")[bool(show.subtitles)]}" width="16" height="16"/></td>
                        </tr>
                    % endif
                    <tr>
                        <td class="showLegend">Season Folders:</td>
                        <td><img
                                src="/images/${("no16.png", "yes16.png")[bool(not show.flatten_folders or sickrage.srCore.srConfig.NAMING_FORCE_FOLDERS)]}"
                                alt=="${("N", "Y")[bool(not show.flatten_folders or sickrage.srCore.srConfig.NAMING_FORCE_FOLDERS)]}"
                                width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Paused:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.paused)]}"
                                 alt="${("N", "Y")[bool(show.paused)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Air-by-Date:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.air_by_date)]}"
                                 alt="${("N", "Y")[bool(show.air_by_date)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Sports:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.is_sports)]}"
                                 alt="${("N", "Y")[bool(show.is_sports)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Anime:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.is_anime)]}"
                                 alt="${("N", "Y")[bool(show.is_anime)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">DVD Order:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.dvdorder)]}"
                                 alt="${("N", "Y")[bool(show.dvdorder)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Scene Numbering:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.scene)]}"
                                 alt="${("N", "Y")[bool(show.scene)]}" width="16" height="16"/></td>
                    </tr>
                    <tr>
                        <td class="showLegend">Archive First Match:</td>
                        <td><img src="/images/${("no16.png", "yes16.png")[bool(show.archive_firstmatch)]}"
                                 alt="${("N", "Y")[bool(show.archive_firstmatch)]}" width="16" height="16"/></td>
                    </tr>
                </table>
            </div>
        </div>
    </div>

    <div class="clearfix"></div>

    <div class="pull-left">
        <div style="padding-bottom: 5px;">
            Change selected episodes to:<br/>
            <select id="statusSelect" class="form-control form-control-inline input-sm">
                <% availableStatus = [WANTED, SKIPPED, IGNORED, FAILED] %>
                % if not sickrage.srCore.srConfig.USE_FAILED_DOWNLOADS:
                    <% availableStatus.remove(FAILED) %>
                % endif
                % for curStatus in availableStatus + sorted(Quality.DOWNLOADED) + sorted(Quality.ARCHIVED):
                    % if curStatus not in [DOWNLOADED, ARCHIVED]:
                        <option value="${curStatus}">${statusStrings[curStatus]}</option>
                    % endif
                % endfor
            </select>
            <input type="hidden" id="showID" value="${show.indexerid}"/>
            <input type="hidden" id="indexer" value="${show.indexer}"/>
        </div>

        <div class="pull-left">
            <input class="btn btn-inline" type="button" id="changeStatus" value="Go"/>
            <input class="btn btn-inline" type="button" id="deleteEpisode" value="Delete Episodes"/>
        </div>
    </div>

    <br/>

    <div class="pull-right clearfix" id="checkboxControls">
        <div style="padding-bottom: 5px;">
            <label for="wanted"><span class="wanted"><input type="checkbox" id="wanted"
                                                            checked="checked"/> Wanted: <b>${epCounts[Overview.WANTED]}</b></span></label>
            <label for="qual"><span class="qual"><input type="checkbox" id="qual"
                                                        checked="checked"/> Low Quality: <b>${epCounts[Overview.QUAL]}</b></span></label>
            <label for="good"><span class="good"><input type="checkbox" id="good"
                                                        checked="checked"/> Downloaded: <b>${epCounts[Overview.GOOD]}</b></span></label>
            <label for="skipped"><span class="skipped"><input type="checkbox" id="skipped" checked="checked"/> Skipped: <b>${epCounts[Overview.SKIPPED]}</b></span></label>
            <label for="snatched"><span class="snatched"><input type="checkbox" id="snatched" checked="checked"/> Snatched: <b>${epCounts[Overview.SNATCHED]}</b></span></label>
        </div>

        <button id="popover" type="button" class="btn btn-xs">Select Columns <b class="caret"></b></button>
        <div class="pull-right">
            <button class="btn btn-xs seriesCheck">Select Filtered Episodes</button>
            <button class="btn btn-xs clearAll">Clear All</button>
        </div>
    </div>
    <br/>
    <br/>
    <br/>

    <table id="${("showTable", "animeTable")[bool(show.is_anime)]}" class="displayShowTable display_show"
           cellspacing="0" border="0" cellpadding="0">


        <% curSeason = -1 %>
        <% odd = 0 %>

        % for epResult in episodeResults:
        <%
            epStr = str(epResult["season"]) + "x" + str(epResult["episode"])
            if not epStr in epCats or not sickrage.srCore.srConfig.DISPLAY_SHOW_SPECIALS and int(epResult["season"]) == 0:
                        next

            scene = False
            scene_anime = False
            if not show.air_by_date and not show.is_sports and not show.is_anime and show.is_scene:
                        scene = True
            elif not show.air_by_date and not show.is_sports and show.is_anime and show.is_scene:
                        scene_anime = True

            (dfltSeas, dfltEpis, dfltAbsolute) = (0, 0, 0)
            if (epResult["season"], epResult["episode"]) in xem_numbering:
                        (dfltSeas, dfltEpis) = xem_numbering[(epResult["season"], epResult["episode"])]

            if epResult["absolute_number"] in xem_absolute_numbering:
                        dfltAbsolute = xem_absolute_numbering[epResult["absolute_number"]]

            if epResult["absolute_number"] in scene_absolute_numbering:
                        scAbsolute = scene_absolute_numbering[epResult["absolute_number"]]
                        dfltAbsNumbering = False
            else:
                        scAbsolute = dfltAbsolute
                        dfltAbsNumbering = True

            if (epResult["season"], epResult["episode"]) in scene_numbering:
                        (scSeas, scEpis) = scene_numbering[(epResult["season"], epResult["episode"])]
                        dfltEpNumbering = False
            else:
                        (scSeas, scEpis) = (dfltSeas, dfltEpis)
                        dfltEpNumbering = True

            epLoc = epResult["location"]
            if epLoc and os.path.isdir(showLoc) and epLoc.lower().startswith(showLoc.lower()):
                        epLoc = epLoc[len(showLoc)+1:]
        %>

        % if int(epResult["season"]) != curSeason:
            % if curSeason == -1:
                <thead>
                <tr class="seasoncols" style="display:none;">
                    <th data-sorter="false" data-priority="critical" class="col-checkbox">
                        <input type="checkbox" class="seasonCheck"/>
                    </th>
                    <th data-sorter="false" class="col-metadata">NFO</th>
                    <th data-sorter="false" class="col-metadata">TBN</th>
                    <th data-sorter="false" class="col-ep">Episode</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(show.is_anime)]}>Absolute
                    </th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene)]}>Scene
                    </th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene_anime)]}>Scene Absolute
                    </th>
                    <th data-sorter="false" class="col-name">Name</th>
                    <th data-sorter="false" class="col-name columnSelector-false">File Name</th>
                    <th data-sorter="false" class="col-ep columnSelector-false">Size</th>
                    <th data-sorter="false" class="col-airdate">Airdate</th>
                    <th data-sorter="false" class="col-status">Status</th>
                    <th data-sorter="false" class="col-search">Search</th>
                </tr>
                </thead>

                <tbody class="tablesorter-no-sort">
                <tr style="height: 60px;">
                    <th class="row-seasonheader displayShowTable" colspan="26"
                        style="vertical-align: bottom; width: auto;">
                        <h3 style="display: inline;"><a
                                name="season-${epResult["season"]}"></a>${("Specials", "Season " + str(epResult["season"]))[int(epResult["season"]) > 0]}
                        </h3>
                        % if sickrage.srCore.srConfig.DISPLAY_ALL_SEASONS == False:
                            <button id="showseason-${epResult['season']}" type="button"
                                    class="btn btn-xs pull-right" data-toggle="collapse"
                                    data-target="#collapseSeason-${epResult['season']}">Show Episodes
                            </button>
                            <script type="text/javascript">
                                $(function () {
                                    $('#collapseSeason-${epResult['season']}').on('hide.bs.collapse', function () {
                                        $('#showseason-${epResult['season']}').text('Show Episodes');
                                    });
                                    $('#collapseSeason-${epResult['season']}').on('show.bs.collapse', function () {
                                        $('#showseason-${epResult['season']}').text('Hide Episodes');
                                    })
                                });
                            </script>
                        % endif
                    </th>
                </tr>
                <tr id="season-${epResult["season"]}-cols" class="seasoncols">
                    <th class="col-checkbox"><input type="checkbox" class="seasonCheck" id="${epResult["season"]}"
                                                    title=""/>
                    </th>
                    <th class="col-metadata">NFO</th>
                    <th class="col-metadata">TBN</th>
                    <th class="col-ep">Episode</th>
                    <th class="col-ep">Absolute</th>
                    <th class="col-ep">Scene</th>
                    <th class="col-ep">Scene Absolute</th>
                    <th class="col-name">Name</th>
                    <th class="col-name">File Name</th>
                    <th class="col-ep">Size</th>
                    <th class="col-airdate">Airdate</th>
                    <th class="col-ep">Download</th>
                    <th class="col-ep">Subtitles</th>
                    <th class="col-status">Status</th>
                    <th class="col-search">Search</th>
                </tr>
                </tbody>
            % else:
                <tbody class="tablesorter-no-sort">
                <tr style="height: 60px;">
                    <th class="row-seasonheader displayShowTable" colspan="26"
                        style="vertical-align: bottom; width: auto;">
                        <h3 style="display: inline;"><a
                                name="season-${epResult["season"]}"></a>${("Specials", "Season " + str(epResult["season"]))[bool(int(epResult["season"]))]}
                        </h3>
                        % if sickrage.srCore.srConfig.DISPLAY_ALL_SEASONS == False:
                            <button id="showseason-${epResult['season']}" type="button"
                                    class="btn btn-xs pull-right" data-toggle="collapse"
                                    data-target="#collapseSeason-${epResult['season']}">Show Episodes
                            </button>
                            <script type="text/javascript">
                                $(function () {
                                    $('#collapseSeason-${epResult['season']}').on('hide.bs.collapse', function () {
                                        $('#showseason-${epResult['season']}').text('Show Episodes');
                                    });
                                    $('#collapseSeason-${epResult['season']}').on('show.bs.collapse', function () {
                                        $('#showseason-${epResult['season']}').text('Hide Episodes');
                                    })
                                });
                            </script>
                        % endif
                    </th>
                </tr>
                <tr id="season-${epResult["season"]}-cols" class="seasoncols">
                    <th class="col-checkbox"><input type="checkbox" class="seasonCheck" id="${epResult["season"]}"
                                                    title=""/>
                    </th>
                    <th class="col-metadata">NFO</th>
                    <th class="col-metadata">TBN</th>
                    <th class="col-ep">Episode</th>
                    <th class="col-ep">Absolute</th>
                    <th class="col-ep">Scene</th>
                    <th class="col-ep">Scene Absolute</th>
                    <th class="col-name">Name</th>
                    <th class="col-name">File Name</th>
                    <th class="col-ep">Size</th>
                    <th class="col-airdate">Airdate</th>
                    <th class="col-ep">Download</th>
                    <th class="col-ep">Subtitles</th>
                    <th class="col-status">Status</th>
                    <th class="col-search">Search</th>
                </tr>
                </tbody>
            % endif
            <% curSeason = int(epResult["season"]) %>
        % endif

        % if sickrage.srCore.srConfig.DISPLAY_ALL_SEASONS == False:
            <tbody class="collapse${("", " in")[curSeason == -1]}" id="collapseSeason-${epResult['season']}">
        % else:
            <tbody>
        % endif

        <tr class="${Overview.overviewStrings[epCats[epStr]]} season-${curSeason} seasonstyle"
            id="${'S' + str(epResult["season"]) + 'E' + str(epResult["episode"])}">

            <td class="col-checkbox">
                % if int(epResult["status"]) != UNAIRED:
                    <input type="checkbox" class="epCheck"
                           id="${str(epResult["season"])+'x'+str(epResult["episode"])}"
                           name="${str(epResult["season"]) +"x"+str(epResult["episode"])}" title=""/>
                % endif
            </td>

            <td align="center"><img src="/images/${("nfo-no.gif", "nfo.gif")[epResult["hasnfo"]]}"
                                    alt="${("N", "Y")[epResult["hasnfo"]]}" width="23" height="11"/></td>

            <td align="center"><img src="/images/${("tbn-no.gif", "tbn.gif")[epResult["hastbn"]]}"
                                    alt="${("N", "Y")[epResult["hastbn"]]}" width="23" height="11"/></td>

            <td align="center">
                <%
                    text = str(epResult['episode'])
                    if epLoc != '' and epLoc is not None:
                                text = '<span title="' + epLoc + '" class="addQTip">' + text + "</span>"
                %>
                    ${text}
            </td>

            <td align="center">${epResult["absolute_number"]}</td>

            <td align="center">
                <input type="text" placeholder="${str(dfltSeas) + 'x' + str(dfltEpis)}" size="6" maxlength="8"
                       class="sceneSeasonXEpisode form-control input-scene" data-for-season="${epResult["season"]}"
                       data-for-episode="${epResult["episode"]}"
                       id="sceneSeasonXEpisode_${show.indexerid}_${str(epResult["season"])}_${str(epResult["episode"])}"
                       title="Change the value here if scene numbering differs from the indexer episode numbering"
                    % if dfltEpNumbering:
                       value=""
                    % else:
                       value="${str(scSeas)}x${str(scEpis)}"
                    % endif
                       style="padding: 0; text-align: center; max-width: 60px;"/>
            </td>

            <td align="center">
                <input type="text" placeholder="${str(dfltAbsolute)}" size="6" maxlength="8"
                       class="sceneAbsolute form-control input-scene"
                       data-for-absolute="${epResult["absolute_number"]}"
                       id="sceneAbsolute_${show.indexerid}${"_"+str(epResult["absolute_number"])}"
                       title="Change the value here if scene absolute numbering differs from the indexer absolute numbering"
                    % if dfltAbsNumbering:
                       value=""
                    % else:
                       value="${str(scAbsolute)}"
                    % endif
                       style="padding: 0; text-align: center; max-width: 60px;"/>
            </td>

            <td class="col-name">
                % if epResult["description"]:
                    <img src="/images/info32.png" width="16" height="16" class="plotInfo" alt=""
                         id="plot_info_${str(show.indexerid)}_${str(epResult["season"])}_${str(epResult["episode"])}"
                         data-tooltip="${epResult["description"]}"/>
                % else:
                    <img src="/images/info32.png" width="16" height="16" class="plotInfoNone" alt=""
                         id="plot_info_${str(show.indexerid)}_${str(epResult["season"])}_${str(epResult["episode"])}"
                         data-tooltip=""/>
                % endif

                ${epResult["name"]}
            </td>

            <td class="col-name">${epLoc}</td>

            <td class="col-ep">
                % if epResult["file_size"]:
                        <% file_size = pretty_filesize(epResult["file_size"]) %>
                ${file_size}
                % endif
            </td>

            <td class="col-airdate">
                % if int(epResult['airdate']) != 1:
                <% airDate = datetime.datetime.fromordinal(epResult['airdate']) %>

                % if airDate.year >= 1970 or show.network:
                    <% airDate = srdatetime.srDateTime.convert_to_setting(tz_updater.parse_date_time(epResult['airdate'], show.airs, show.network)) %>
                % endif

                    <time datetime="${airDate.isoformat()}"
                          class="date">${srdatetime.srDateTime.srfdatetime(airDate)}</time>
                % else:
                    Never
                % endif
            </td>

            <td>
                % if sickrage.srCore.srConfig.DOWNLOAD_URL and epResult['location']:
                <%
                    filename = epResult['location']
                    for rootDir in sickrage.srCore.srConfig.ROOT_DIRS.split('|'):
                                if rootDir.startswith('/'):
                                    filename = filename.replace(rootDir, "")
                    filename = sickrage.srCore.srConfig.DOWNLOAD_URL + urllib.quote(filename.encode('utf8'))
                %>
                    <div style="text-align: center;"><a href="${filename}">Download</a></div>
                % endif
            </td>

            <td class="col-subtitles" align="center">
                % for sub_lang in [subtitle_searcher.fromietf(x) for x in epResult["subtitles"].split(',') if epResult["subtitles"]]:
                <% flag = sub_lang.opensubtitles %>
                % if (not sickrage.srCore.srConfig.SUBTITLES_MULTI and len(subtitle_searcher.wantedLanguages()) is 1) and subtitle_searcher.wantedLanguages()[0] in sub_lang.opensubtitles:
                    <% flag = 'checkbox' %>
                % endif
                    <img src="/images/subtitles/flags/${flag}.png" width="16" height="11"
                         alt="${sub_lang.name}"
                         onError="this.onerror=null;this.src='/images/flags/unknown.png';"/>
                % endfor
            </td>

            <% curStatus, curQuality = Quality.splitCompositeStatus(int(epResult["status"])) %>
            % if curQuality != Quality.NONE:
                <td class="col-status">${statusStrings[curStatus]} ${renderQualityPill(curQuality)}</td>
            % else:
                <td class="col-status">${statusStrings[curStatus]}</td>
            % endif

            <td class="col-search">
                % if int(epResult["season"]) != 0:
                    % if ( int(epResult["status"]) in Quality.SNATCHED + Quality.DOWNLOADED ) and sickrage.srCore.srConfig.USE_FAILED_DOWNLOADS:
                        <a class="epRetry"
                           id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}"
                           name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}"
                           href="retryEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img
                                src="/images/search16.png" height="16" alt="retry" title="Retry Download"/></a>
                    % else:
                        <a class="epSearch"
                           id="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}"
                           name="${str(show.indexerid)}x${str(epResult["season"])}x${str(epResult["episode"])}"
                           href="searchEpisode?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img
                                src="/images/search16.png" width="16" height="16" alt="search"
                                title="Manual Search"/></a>
                    % endif
                % endif
                % if sickrage.srCore.srConfig.USE_SUBTITLES and show.subtitles and epResult["location"] and frozenset(subtitle_searcher.wantedLanguages()).difference(epResult["subtitles"].split(',')):
                    <a class="epSubtitlesSearch"
                       href="searchEpisodeSubtitles?show=${show.indexerid}&amp;season=${epResult["season"]}&amp;episode=${epResult["episode"]}"><img
                            src="/images/closed_captioning.png" height="16" alt="search subtitles"
                            title="Search Subtitles"/></a>
                % endif
            </td>
        </tr>
        </tbody>
        % endfor
    </table>

    <!--Begin - Bootstrap Modal-->
    <div id="manualSearchModalFailed" class="modal fade">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                    <h4 class="modal-title">Manual Search</h4>
                </div>
                <div class="modal-body">
                    <p>Do you want to mark this episode as failed?</p>
                    <p class="text-warning">
                        <small>The episode release name will be added to the failed history, preventing it to be
                            downloaded again.
                        </small>
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-danger" data-dismiss="modal">No</button>
                    <button type="button" class="btn btn-success" data-dismiss="modal">Failed</button>
                </div>
            </div>
        </div>
    </div>

    <div id="manualSearchModalQuality" class="modal fade">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                    <h4 class="modal-title">Manual Search</h4>
                </div>
                <div class="modal-body">
                    <p>Do you want to include the current episode quality in the search?</p>
                    <p class="text-warning">
                        <small>Choosing No will ignore any releases with the same episode quality as the one currently
                            downloaded/snatched.
                        </small>
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-danger" data-dismiss="modal">No</button>
                    <button type="button" class="btn btn-success" data-dismiss="modal">Yes</button>
                </div>
            </div>
        </div>
    </div>
    <!--End - Bootstrap Modal-->
</%block>

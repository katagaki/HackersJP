//
//  MoreView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import Komponents
import SwiftUI

struct MoreView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            MoreList(repoName: "katagaki/HackersJP", viewPath: ViewPath.moreAttributions) {
                Section {
                    Picker(selection: $settings.startupTab) {
                        Text("フィード")
                            .tag(0)
                        Text("求人")
                            .tag(1)
                        Text("展示")
                            .tag(2)
                    } label: {
                        ListRow(image: "ListIcon.Startup",
                                title: "デフォルトタブ")
                    }
                    NavigationLink(value: ViewPath.moreCache) {
                        ListRow(image: "ListIcon.Cache",
                                title: "キャッシュ管理")
                    }
                } header: {
                    ListSectionHeader(text: "一般")
                        .font(.body)
                }
                Section {
                    Picker(selection: $settings.feedSort) {
                        Text("トップ")
                            .tag(HNStoryType.top)
                        Text("新しい順")
                            .tag(HNStoryType.new)
                        Text("ベスト")
                            .tag(HNStoryType.best)
                    } label: {
                        ListRow(image: "ListIcon.Sort",
                                title: "並べ替え")
                    }
                    Picker(selection: $settings.pageStoryCount) {
                        Text("10件")
                            .tag(10)
                        Text("20件")
                            .tag(20)
                        Text("30件")
                            .tag(30)
                    } label: {
                        ListRow(image: "ListIcon.PageStoryCount",
                                title: "ページの記事数")
                    }
                } header: {
                    ListSectionHeader(text: "フィード")
                        .font(.body)
                }
                Section {
                    Picker(selection: $settings.titleLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Title",
                                title: "タイトルおよび内容",
                                subtitle: settings.titleLanguage == 0 ? "オフラインで翻訳されます。" : "英語の原文で表示されます。")
                    }
                    Picker(selection: $settings.commentLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Comment",
                                title: "コメント",
                                subtitle: settings.commentLanguage == 0 ? "オフラインで翻訳されます。" : "英語の原文で表示されます。")
                    }
                    Picker(selection: $settings.linkLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Article",
                                title: "記事",
                                subtitle: settings.linkLanguage == 0 ? "翻訳されたページを開きます。" : "元の記事を開きます。")
                    }
                } header: {
                    ListSectionHeader(text: "言語")
                        .font(.body)
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                // swiftlint:disable line_length
                switch viewPath {
                case .moreCache: CacheView()
                case .moreAttributions: LicensesView(licenses: [
                    License(libraryName: "Alamofire", text:
"""
Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""),
                    License(libraryName: "FaviconFinder", text:
"""
Copyright (c) 2022 William Lumley <will@lumley.io>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""),
                    License(libraryName: "ML Kit", text:
"""
THIS SERVICE MAY CONTAIN TRANSLATIONS POWERED BY GOOGLE. GOOGLE DISCLAIMS ALL WARRANTIES RELATED TO THE TRANSLATIONS, EXPRESS OR IMPLIED, INCLUDING ANY WARRANTIES OF ACCURACY, RELIABILITY, AND ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"""),
                    License(libraryName: "nanopb", text:
"""
Copyright (c) 2011 Petteri Aimonen <jpa at nanopb.mail.kapsi.fi>

This software is provided 'as-is', without any express or
implied warranty. In no event will the authors be held liable
for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you
   must not claim that you wrote the original software. If you use
   this software in a product, an acknowledgment in the product
   documentation would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and
   must not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source
   distribution.
"""),
                    License(libraryName: "SSZipArchive", text:
"""
Copyright (c) 2013-2021, ZipArchive, https://github.com/ZipArchive

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""),
                    License(libraryName: "SwiftSoup", text:
"""
MIT License

Copyright (c) 2016 Nabil Chatbi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""")
                ])
                default: Color.clear
                }
                // swiftlint:enable line_length
            })
            .onChange(of: settings.startupTab) { _, newValue in
                settings.setStartupTab(newValue)
            }
            .onChange(of: settings.feedSort) { _, newValue in
                settings.setFeedSort(newValue)
            }
            .onChange(of: settings.pageStoryCount) { _, newValue in
                settings.setPageStoryCount(newValue)
            }
            .onChange(of: settings.titleLanguage) { _, newValue in
                settings.setTitleLanguage(newValue)
            }
            .onChange(of: settings.commentLanguage) { _, newValue in
                settings.setCommentLanguage(newValue)
            }
            .onChange(of: settings.linkLanguage) { _, newValue in
                settings.setLinkLanguage(newValue)
            }
            .navigationTitle("その他")
        }
    }
}

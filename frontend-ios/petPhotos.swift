import SwiftUI

struct PetPhotosView: View {
    @EnvironmentObject var router: Router
    let photos = MockData.photos
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Photo Gallery").font(DesignTokens.Typography.headline)
                    Spacer()
                    CircularIconButton(icon: "camera.fill") {}
                }
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            AsyncImage(url: URL(string: photo.url)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .cornerRadius(DesignTokens.Radius.m)
                            .clipped()
                            .overlay(
                                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(photo.isFavorite ? .pink : .white)
                                    .padding(8),
                                alignment: .bottomTrailing
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct PetPhotosView_Preview: PreviewProvider {
    static var previews: some View {
        PetPhotosView().environmentObject(Router())
    }
}
